defmodule FleetMint.Transit do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Transit.{Schedule, Booking, Ticket, BusCheckpoint, MinibusTrip}
  alias FleetMint.Transport.Fleet.{Vehicle, Route}

  # ── Minibus Trips ─────────────────────────────────────────────────────────

  def list_minibus_trips do
    MinibusTrip
    |> order_by([t], desc: t.date)
    |> preload([:bus, :route, :driver])
    |> Repo.all()
  end

  def get_minibus_trip!(id) do
    MinibusTrip |> preload([:bus, :route, :driver]) |> Repo.get!(id)
  end

  def create_minibus_trip(attrs \\ %{}) do
    %MinibusTrip{} |> MinibusTrip.changeset(attrs) |> Repo.insert()
  end

  def update_minibus_trip(%MinibusTrip{} = trip, attrs) do
    trip |> MinibusTrip.changeset(attrs) |> Repo.update()
  end

  def delete_minibus_trip(%MinibusTrip{} = trip), do: Repo.delete(trip)

  def change_minibus_trip(%MinibusTrip{} = trip, attrs \\ %{}),
    do: MinibusTrip.changeset(trip, attrs)

  def count_minibus_trips_today do
    today = Date.utc_today()
    Repo.aggregate(from(t in MinibusTrip, where: t.date == ^today), :count)
  end

  def minibus_revenue_today do
    today = Date.utc_today()
    Repo.aggregate(from(t in MinibusTrip, where: t.date == ^today), :sum, :fare_collected)
    |> Kernel.||(Decimal.new(0))
  end

  # ── Schedules ─────────────────────────────────────────────────────────────

  def list_schedules(opts \\ []) do
    Schedule
    |> maybe_filter_status(opts[:status])
    |> preload([:route, :vehicle, :driver, :conductor, :operator])
    |> order_by([s], s.departure_time)
    |> Repo.all()
  end

  def list_public_schedules_for_operator(operator_id) do
    from(s in Schedule,
      where: s.operator_id == ^operator_id and s.status == "active",
      preload: [:route, vehicle: :bus_profile],
      order_by: s.departure_time
    ) |> Repo.all()
  end

  def get_schedule!(id), do: Repo.get!(Schedule, id) |> Repo.preload([:route, :vehicle, :driver, :conductor, :operator])

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
    case Repo.insert(changeset) do
      {:ok, booking} ->
        booking = Repo.preload(booking, [:schedule])
        decrement_available_seats(booking.schedule_id)
        {:ok, ticket} = issue_ticket(booking)
        booking = %{booking | ticket: ticket}
        Phoenix.PubSub.broadcast(FleetMint.PubSub, "bookings:new", {:new_booking, booking})
        {:ok, booking}
      err -> err
    end
  end

  def update_booking(%Booking{} = booking, attrs) do
    booking |> Booking.changeset(attrs) |> Repo.update()
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
    case booking |> Booking.changeset(%{status: "cancelled"}) |> Repo.update() do
      {:ok, cancelled} ->
        increment_available_seats(booking.schedule_id)
        {:ok, cancelled}
      err -> err
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

  def validate_ticket(ticket_number, _mode \\ :static) do
    case Repo.get_by(Ticket, ticket_number: ticket_number) |> Repo.preload(booking: [:schedule]) do
      nil -> {:error, :not_found}
      %Ticket{status: "boarded"} -> {:error, :already_boarded}
      %Ticket{status: "cancelled"} -> {:error, :cancelled}
      %Ticket{expires_at: exp} = ticket when not is_nil(exp) ->
        if NaiveDateTime.compare(exp, NaiveDateTime.utc_now()) == :lt do
          {:error, :expired}
        else
          do_board_ticket(ticket)
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
    secret =
      Application.get_env(:fleet_mint, :qr_secret) ||
        raise "`:qr_secret` is not set for :fleet_mint — configure it in runtime.exs to prevent ticket forgery"

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

  defp decrement_available_seats(schedule_id) do
    from(s in Schedule, where: s.id == ^schedule_id and s.available_seats > 0)
    |> Repo.update_all(inc: [available_seats: -1])
  end

  defp increment_available_seats(schedule_id) do
    from(s in Schedule, where: s.id == ^schedule_id)
    |> Repo.update_all(inc: [available_seats: 1])
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

  # ── Bus Checkpoints (live location reporting) ─────────────────────────────

  def post_checkpoint(attrs) do
    %BusCheckpoint{} |> BusCheckpoint.changeset(attrs) |> Repo.insert()
  end

  def get_latest_checkpoint(schedule_id, %Date{} = date) do
    from(c in BusCheckpoint,
      where: c.schedule_id == ^schedule_id and c.travel_date == ^date,
      order_by: [desc: c.inserted_at],
      limit: 1,
      preload: [:reported_by]
    ) |> Repo.one()
  end

  def list_checkpoints(schedule_id, %Date{} = date) do
    from(c in BusCheckpoint,
      where: c.schedule_id == ^schedule_id and c.travel_date == ^date,
      order_by: [desc: c.inserted_at],
      preload: [:reported_by]
    ) |> Repo.all()
  end

  def track_by_booking_reference(ref) do
    booking =
      from(b in Booking,
        where: b.booking_reference == ^ref,
        preload: [schedule: [:route, :operator]]
      ) |> Repo.one()

    case booking do
      nil -> {:error, :not_found}
      b ->
        checkpoint = get_latest_checkpoint(b.schedule_id, b.travel_date)
        all_checkpoints = list_checkpoints(b.schedule_id, b.travel_date)
        {:ok, %{booking: b, checkpoint: checkpoint, history: all_checkpoints}}
    end
  end

  def change_checkpoint(%BusCheckpoint{} = cp, attrs \\ %{}) do
    BusCheckpoint.changeset(cp, attrs)
  end
end
