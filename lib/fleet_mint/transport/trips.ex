defmodule FleetMint.Transport.Trips do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Accounting
  alias FleetMint.Transport.Trips.{Schedule, MinibusTrip, Trip}

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
    changeset = MinibusTrip.changeset(%MinibusTrip{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:minibus_trip, changeset)
    |> Ecto.Multi.run(:revenue_entry, fn _repo, %{minibus_trip: trip} ->
      maybe_record_amount("revenue", "MinibusTrip", trip.id, trip.fare_collected, "Fare collected for trip on #{trip.date}")
    end)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{minibus_trip: trip} ->
      maybe_record_amount("expense", "MinibusTrip", trip.id, trip.fuel_cost, "Fuel cost for trip on #{trip.date}")
    end)
    |> Repo.transaction()
    |> unwrap_multi(:minibus_trip)
  end

  def update_minibus_trip(%MinibusTrip{} = trip, attrs) do
    changeset = MinibusTrip.changeset(trip, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:minibus_trip, changeset)
    |> Ecto.Multi.run(:revenue_entry, fn _repo, %{minibus_trip: updated} ->
      sync_amount("revenue", "MinibusTrip", updated.id, updated.fare_collected, "Fare collected for trip on #{updated.date}")
    end)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{minibus_trip: updated} ->
      sync_amount("expense", "MinibusTrip", updated.id, updated.fuel_cost, "Fuel cost for trip on #{updated.date}")
    end)
    |> Repo.transaction()
    |> unwrap_multi(:minibus_trip)
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
    |> maybe_filter_organisation(opts[:organisation_id])
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

  # ── Trips (canonical Route → Schedule → Trip; one Schedule instance) ──────

  def list_trips(opts \\ []) do
    Trip
    |> maybe_filter_trip_organisation(opts[:organisation_id])
    |> preload([:schedule, :vehicle, :driver, :conductor])
    |> order_by([t], desc: t.travel_date)
    |> Repo.all()
  end

  def get_trip!(id), do: Repo.get!(Trip, id) |> Repo.preload([:schedule, :vehicle, :driver, :conductor])

  @doc """
  Finds the Trip for this (schedule, day), creating it if this is the
  first thing (a checkpoint, a dispatch action, ...) to reference that
  pair. organisation_id is always derived from the schedule's operator —
  never accepted from a caller.
  """
  def get_or_create_trip(schedule_id, %Date{} = travel_date) do
    case Repo.get_by(Trip, schedule_id: schedule_id, travel_date: travel_date) do
      %Trip{} = trip ->
        {:ok, trip}

      nil ->
        organisation_id =
          from(s in Schedule,
            join: o in assoc(s, :operator),
            where: s.id == ^schedule_id,
            select: o.organisation_id
          )
          |> Repo.one()

        %Trip{}
        |> Trip.changeset(%{schedule_id: schedule_id, travel_date: travel_date, organisation_id: organisation_id, status: "planned"})
        |> Repo.insert()
    end
  end

  def update_trip_status(%Trip{} = trip, status) do
    trip |> Trip.status_changeset(status) |> Repo.update()
  end

  @doc """
  Trips within `window_days` of `date`, closest first — the candidate list
  for manually matching a CashingReport to a Trip (see
  `FleetMintWeb.CashingReportController.edit_trip_match/2`).
  """
  def list_trips_near_date(organisation_id, %Date{} = date, window_days \\ 3) do
    from(t in Trip,
      where: t.organisation_id == ^organisation_id,
      where: t.travel_date >= ^Date.add(date, -window_days) and t.travel_date <= ^Date.add(date, window_days),
      preload: [:schedule, :vehicle, :driver],
      order_by: [asc: fragment("abs(? - ?)", t.travel_date, ^date)]
    )
    |> Repo.all()
  end

  def change_trip(%Trip{} = trip, attrs \\ %{}), do: Trip.changeset(trip, attrs)

  defp maybe_filter_trip_organisation(query, nil), do: query
  defp maybe_filter_trip_organisation(query, :all), do: query
  defp maybe_filter_trip_organisation(query, organisation_id), do: where(query, [t], t.organisation_id == ^organisation_id)

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

  defp maybe_filter_organisation(query, nil), do: query
  defp maybe_filter_organisation(query, :all), do: query
  defp maybe_filter_organisation(query, organisation_id) do
    query
    |> join(:inner, [s], o in assoc(s, :operator), as: :operator)
    |> where([operator: o], o.organisation_id == ^organisation_id)
  end

  # ── Private ledger helpers ─────────────────────────────────────────────────

  defp maybe_record_amount(entry_type, source_type, source_id, amount, description) do
    if amount && Decimal.compare(amount, Decimal.new(0)) == :gt do
      Accounting.record_entry(%{
        entry_type: entry_type,
        source_type: source_type,
        source_id: source_id,
        amount: amount,
        description: description
      })
    else
      {:ok, nil}
    end
  end

  defp sync_amount(entry_type, source_type, source_id, amount, description) do
    existing = Accounting.entries_for_source(source_type, source_id, entry_type)
    positive? = amount && Decimal.compare(amount, Decimal.new(0)) == :gt

    case {existing, positive?} do
      {[], true} -> maybe_record_amount(entry_type, source_type, source_id, amount, description)
      {[], false} -> {:ok, nil}
      {[entry], true} -> entry |> Accounting.change_entry(%{amount: amount}) |> Repo.update()
      {[entry], false} -> Repo.delete(entry)
    end
  end

  defp unwrap_multi(multi_result, ok_key) do
    case multi_result do
      {:ok, changes} -> {:ok, Map.fetch!(changes, ok_key)}
      {:error, _failed_step, failed_value, _changes} -> {:error, failed_value}
    end
  end
end
