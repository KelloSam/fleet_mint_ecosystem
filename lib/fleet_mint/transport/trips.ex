defmodule FleetMint.Transport.Trips do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Transport.Trips.{Schedule, MinibusTrip}

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

  # ── Seat inventory (called from Transport.Ticketing on booking/cancel) ────

  def decrement_available_seat(schedule_id) do
    from(s in Schedule, where: s.id == ^schedule_id and s.available_seats > 0)
    |> Repo.update_all(inc: [available_seats: -1])
  end

  def increment_available_seat(schedule_id) do
    from(s in Schedule, where: s.id == ^schedule_id)
    |> Repo.update_all(inc: [available_seats: 1])
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [s], s.status == ^status)
end
