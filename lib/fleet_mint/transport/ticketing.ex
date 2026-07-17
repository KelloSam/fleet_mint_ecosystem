defmodule FleetMint.Transport.Ticketing do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Accounting
  alias FleetMint.Transport.Ticketing.{Booking, Ticket}
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Trips.Schedule

  # ── Bookings ──────────────────────────────────────────────────────────────

  def list_bookings(opts \\ []) do
    Booking
    |> maybe_filter_date(opts[:travel_date])
    |> maybe_filter_status(opts[:status])
    |> preload([:schedule, :booked_by, ticket: []])
    |> order_by([b], [desc: b.inserted_at])
    |> Repo.all()
  end

  def list_bookings_paginated(page \\ 1, opts \\ []) do
    query =
      Booking
      |> maybe_filter_date(opts[:travel_date])
      |> maybe_filter_status(opts[:status])
      |> preload([:schedule, :booked_by, ticket: []])
      |> order_by([b], desc: b.inserted_at)
    FleetMint.Pagination.paginate(query, page)
  end

  def get_booking!(id), do: Repo.get!(Booking, id) |> Repo.preload([:schedule, :booked_by, :ticket])
  def get_booking_by_reference!(ref), do: Repo.get_by!(Booking, booking_reference: ref) |> Repo.preload([:schedule, :ticket])

  def create_booking(attrs, user_id \\ nil) do
    attrs = if user_id, do: Map.put(attrs, "booked_by_id", user_id), else: attrs
    changeset = if user_id,
      do: Booking.internal_changeset(%Booking{}, attrs),
      else: Booking.changeset(%Booking{}, attrs)
    changeset = validate_seat_against_map(changeset)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:booking, changeset)
    |> Accounting.multi_insert_entry(:ledger_entry, fn %{booking: booking} ->
      %{
        entry_type: "revenue",
        source_type: "Booking",
        source_id: booking.id,
        amount: booking.fare_paid,
        payment_method: booking.payment_method,
        reference_number: booking.payment_reference,
        recorded_by_id: user_id,
        description: "Fare for booking #{booking.booking_reference}"
      }
    end)
    |> Ecto.Multi.run(:seat, fn _repo, %{booking: booking} ->
      case Trips.decrement_available_seat(booking.schedule_id) do
        {1, _} ->
          {:ok, nil}

        {0, _} ->
          {:error,
           booking
           |> Ecto.Changeset.change()
           |> Ecto.Changeset.add_error(:schedule_id, "no seats available on this schedule")
           |> Map.put(:action, :insert)}
      end
    end)
    |> Ecto.Multi.run(:ticket, fn _repo, %{booking: booking} ->
      issue_ticket(booking)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{booking: booking, ticket: ticket}} ->
        booking = booking |> Repo.preload([:schedule]) |> Map.put(:ticket, ticket)
        Phoenix.PubSub.broadcast(FleetMint.PubSub, "bookings:new", {:new_booking, booking})
        {:ok, booking}

      {:error, _failed_step, failed_value, _changes} ->
        {:error, failed_value}
    end
  end

  def update_booking(%Booking{} = booking, attrs) do
    changeset = Booking.changeset(booking, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:booking, changeset)
    |> Ecto.Multi.run(:ledger_entry, fn _repo, %{booking: updated} ->
      case Accounting.entries_for_source("Booking", updated.id, "revenue") do
        [entry] ->
          entry
          |> Accounting.change_entry(%{
            amount: updated.fare_paid,
            payment_method: updated.payment_method,
            reference_number: updated.payment_reference
          })
          |> Repo.update()

        [] ->
          {:ok, nil}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{booking: booking}} -> {:ok, booking}
      {:error, _failed_step, failed_value, _changes} -> {:error, failed_value}
    end
  end

  def list_bookings_since(%NaiveDateTime{} = since) do
    Booking
    |> where([b], b.inserted_at > ^since)
    |> order_by([b], desc: b.inserted_at)
    |> preload([:schedule])
    |> Repo.all()
  end

  def count_bookings_today do
    today = Date.utc_today()
    Booking |> where([b], b.travel_date == ^today and b.status != "cancelled") |> Repo.aggregate(:count, :id)
  end

  def revenue_today do
    today = Date.utc_today()
    result = Booking
    |> where([b], b.travel_date == ^today and b.status != "cancelled")
    |> select([b], sum(b.fare_paid))
    |> Repo.one()
    result || Decimal.new("0.00")
  end

  def get_booked_seats(schedule_id, %Date{} = date) do
    Booking
    |> where([b], b.schedule_id == ^schedule_id and b.travel_date == ^date and b.status != "cancelled")
    |> select([b], b.seat_number)
    |> Repo.all()
    |> Enum.reject(&is_nil/1)
  end

  def cancel_booking(%Booking{} = booking) do
    booking = Repo.preload(booking, :ticket)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:booking, Booking.changeset(booking, %{status: "cancelled"}))
    |> Accounting.multi_reverse_entry(
      :refund_entry,
      fn _changes ->
        "Booking" |> Accounting.entries_for_source(booking.id, "revenue") |> List.first()
      end,
      %{description: "Refund for cancelled booking #{booking.booking_reference}"}
    )
    |> Ecto.Multi.run(:seat, fn _repo, %{booking: cancelled} ->
      Trips.increment_available_seat(cancelled.schedule_id)
      {:ok, nil}
    end)
    |> Ecto.Multi.run(:ticket, fn _repo, _changes ->
      case booking.ticket do
        nil -> {:ok, nil}
        ticket -> ticket |> Ticket.cancel_changeset() |> Repo.update()
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{booking: cancelled}} -> {:ok, cancelled}
      {:error, _failed_step, failed_value, _changes} -> {:error, failed_value}
    end
  end

  def change_booking(%Booking{} = booking, attrs \\ %{}), do: Booking.changeset(booking, attrs)

  # ── Tickets ───────────────────────────────────────────────────────────────

  def issue_ticket(%Booking{} = booking) do
    booking = Repo.preload(booking, :schedule)
    token = generate_validation_token(booking)
    qr_payload = build_qr_payload(booking, token)
    qr_svg = generate_qr_svg(qr_payload)
    expires_at = NaiveDateTime.add(NaiveDateTime.utc_now(), 24 * 60 * 60, :second)

    %Ticket{}
    |> Ticket.changeset(%{
      booking_id: booking.id,
      qr_payload: qr_payload,
      qr_svg: qr_svg,
      validation_token: token,
      expires_at: expires_at
    })
    |> Repo.insert()
  end

  def get_ticket_by_number(num), do: Repo.get_by(Ticket, ticket_number: num) |> Repo.preload(booking: [:schedule])

  # ── Private helpers ───────────────────────────────────────────────────────

  defp generate_validation_token(booking) do
    secret =
      Application.get_env(:fleet_mint, :qr_secret) ||
        raise "`:qr_secret` is not set for :fleet_mint — configure it in runtime.exs to prevent ticket forgery"

    data = "#{booking.id}:#{booking.booking_reference}:#{booking.travel_date}"
    :crypto.mac(:hmac, :sha256, secret, data) |> Base.encode16(case: :lower) |> binary_part(0, 16)
  end

  defp build_qr_payload(booking, token) do
    Jason.encode!(%{
      ref: booking.booking_reference,
      bid: booking.id,
      date: to_string(booking.travel_date),
      seat: booking.seat_number,
      tok: token
    })
  end

  defp generate_qr_svg(payload) do
    payload
    |> EQRCode.encode()
    |> EQRCode.svg(width: 200)
  end

  defp validate_seat_against_map(changeset) do
    import Ecto.Changeset, only: [get_field: 2, get_change: 2, add_error: 3]
    alias FleetMint.Transport.Fleet.BusProfile

    with seat when not is_nil(seat) <- get_change(changeset, :seat_number),
         schedule_id when not is_nil(schedule_id) <- get_field(changeset, :schedule_id),
         %Schedule{} = schedule <-
           Repo.get(Schedule, schedule_id) |> Repo.preload(vehicle: :bus_profile),
         %BusProfile{seat_labels: [_ | _] = labels} <-
           schedule.vehicle && schedule.vehicle.bus_profile do
      if seat in labels do
        changeset
      else
        add_error(changeset, :seat_number, "is not valid for this vehicle")
      end
    else
      _ -> changeset
    end
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [s], s.status == ^status)

  defp maybe_filter_date(query, nil), do: query
  defp maybe_filter_date(query, date), do: where(query, [b], b.travel_date == ^date)
end
