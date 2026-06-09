defmodule FleetMint.Transit do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Transit.{Schedule, Booking, Ticket}
  alias FleetMint.Fleet.{Vehicle, Route}

  # ── Schedules ─────────────────────────────────────────────────────────────

  def list_schedules(opts \\ []) do
    Schedule
    |> maybe_filter_status(opts[:status])
    |> preload([:route, :vehicle, :driver, :conductor])
    |> order_by([s], s.departure_time)
    |> Repo.all()
  end

  def get_schedule!(id), do: Repo.get!(Schedule, id) |> Repo.preload([:route, :vehicle, :driver, :conductor])

  def create_schedule(attrs) do
    %Schedule{} |> Schedule.changeset(attrs) |> Repo.insert()
  end

  def update_schedule(%Schedule{} = schedule, attrs) do
    schedule |> Schedule.changeset(attrs) |> Repo.update()
  end

  def delete_schedule(%Schedule{} = schedule), do: Repo.delete(schedule)

  def change_schedule(%Schedule{} = schedule, attrs \\ %{}), do: Schedule.changeset(schedule, attrs)

  # ── Bookings ──────────────────────────────────────────────────────────────

  def list_bookings(opts \\ []) do
    Booking
    |> maybe_filter_date(opts[:travel_date])
    |> maybe_filter_status(opts[:status])
    |> preload([:schedule, :booked_by, ticket: []])
    |> order_by([b], [desc: b.inserted_at])
    |> Repo.all()
  end

  def get_booking!(id), do: Repo.get!(Booking, id) |> Repo.preload([:schedule, :booked_by, :ticket])
  def get_booking_by_reference!(ref), do: Repo.get_by!(Booking, booking_reference: ref) |> Repo.preload([:schedule, :ticket])

  def create_booking(attrs, user_id \\ nil) do
    attrs = if user_id, do: Map.put(attrs, "booked_by_id", user_id), else: attrs
    case %Booking{} |> Booking.changeset(attrs) |> Repo.insert() do
      {:ok, booking} ->
        booking = Repo.preload(booking, [:schedule])
        {:ok, ticket} = issue_ticket(booking)
        {:ok, %{booking | ticket: ticket}}
      err -> err
    end
  end

  def cancel_booking(%Booking{} = booking) do
    booking |> Booking.changeset(%{status: "cancelled"}) |> Repo.update()
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

  def validate_ticket(ticket_number, mode \\ :static) do
    case Repo.get_by(Ticket, ticket_number: ticket_number) |> Repo.preload(booking: [:schedule]) do
      nil -> {:error, :not_found}
      %Ticket{status: "boarded"} -> {:error, :already_boarded}
      %Ticket{status: "cancelled"} -> {:error, :cancelled}
      %Ticket{expires_at: exp} when not is_nil(exp) ->
        if NaiveDateTime.compare(exp, NaiveDateTime.utc_now()) == :lt do
          {:error, :expired}
        else
          do_board_ticket(mode)
        end
      ticket -> do_board_ticket(ticket)
    end
  end

  defp do_board_ticket(ticket) do
    ticket |> Ticket.board_changeset() |> Repo.update()
  end

  def get_ticket_by_number(num), do: Repo.get_by(Ticket, ticket_number: num) |> Repo.preload(booking: [:schedule])

  # ── Private helpers ───────────────────────────────────────────────────────

  defp generate_validation_token(booking) do
    secret = Application.get_env(:fleet_mint, :qr_secret, "fleet_mint_qr_secret")
    data = "#{booking.id}:#{booking.booking_reference}:#{booking.travel_date}"
    :crypto.mac(:hmac, :sha256, secret, data) |> Base.encode16(case: :lower) |> binary_part(0, 16)
  end

  defp build_qr_payload(booking, token) do
    schedule = booking.schedule
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

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [s], s.status == ^status)

  defp maybe_filter_date(query, nil), do: query
  defp maybe_filter_date(query, date), do: where(query, [b], b.travel_date == ^date)
end
