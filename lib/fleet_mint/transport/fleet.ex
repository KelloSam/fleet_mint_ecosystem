defmodule FleetMint.Transport.Fleet do
  @moduledoc """
  The Fleet context.
  
  This context handles operations related to vehicles (buses/trucks) and
  operators — it provides functions to create, read, update, and delete
  fleet assets, as well as more specialized fleet management operations.
  Route network data lives in `FleetMint.Transport.Routes` — a route is a
  geography fact independent of any vehicle assigned to run it.
  """
  
  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Accounting
  alias FleetMint.Identity.Organisation

  alias FleetMint.Transport.Fleet.{Bus, Operator, Branch, Terminal}

  # ── Operators (bus companies) ──────────────────────────────────────────────

  def list_operators do
    from(o in Operator, where: is_nil(o.archived_at), order_by: o.name) |> Repo.all()
  end

  def list_operators_for_public do
    from(o in Operator,
      where: o.active == true and is_nil(o.archived_at),
      left_join: s in assoc(o, :schedules),
      on: s.status == "active",
      group_by: o.id,
      select: %{o | schedule_count: count(s.id)},
      order_by: o.name
    ) |> Repo.all()
  end

  def get_operator!(id), do: Repo.get!(Operator, id)
  def get_operator_by_slug!(slug), do: Repo.get_by!(Operator, slug: slug, active: true)
  def get_operator_by_organisation(organisation_id), do: Repo.get_by(Operator, organisation_id: organisation_id)

  @doc """
  Onboards a new operator (bus company). Every operator is one tenant's
  passenger-transport brand, so this also creates that tenant's
  Organisation in the same transaction — callers only fill in the
  operator form, not two separate records.
  """
  def create_operator(attrs \\ %{}) do
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:organisation, Organisation.changeset(%Organisation{}, attrs))
    |> Ecto.Multi.insert(:operator, fn %{organisation: organisation} ->
      Operator.changeset(%Operator{}, Map.put(attrs, "organisation_id", organisation.id))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{operator: operator}} -> {:ok, operator}
      {:error, _step, failed_value, _changes} -> {:error, failed_value}
    end
  end

  def update_operator(%Operator{} = op, attrs) do
    op |> Operator.changeset(attrs) |> Repo.update()
  end

  def delete_operator(%Operator{} = op) do
    op
    |> Ecto.Changeset.change(archived_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update()
  end

  def change_operator(%Operator{} = op, attrs \\ %{}), do: Operator.changeset(op, attrs)

  def list_inactive_operators do
    from(o in Operator, where: o.active == false and is_nil(o.archived_at), order_by: o.name)
    |> Repo.all()
  end

  # ── Branches and Terminals (tenant org hierarchy) ───────────────────────────

  def list_branches(operator_id) do
    from(b in Branch, where: b.operator_id == ^operator_id, order_by: b.name) |> Repo.all()
  end

  def get_branch!(id), do: Repo.get!(Branch, id)

  def create_branch(attrs \\ %{}) do
    %Branch{} |> Branch.changeset(attrs) |> Repo.insert()
  end

  def update_branch(%Branch{} = branch, attrs) do
    branch |> Branch.changeset(attrs) |> Repo.update()
  end

  def delete_branch(%Branch{} = branch), do: Repo.delete(branch)

  def change_branch(%Branch{} = branch, attrs \\ %{}), do: Branch.changeset(branch, attrs)

  def list_terminals(operator_id) do
    from(t in Terminal, where: t.operator_id == ^operator_id, order_by: t.name) |> Repo.all()
  end

  def list_terminals_for_branch(branch_id) do
    from(t in Terminal, where: t.branch_id == ^branch_id, order_by: t.name) |> Repo.all()
  end

  def get_terminal!(id), do: Repo.get!(Terminal, id)

  def create_terminal(attrs \\ %{}) do
    %Terminal{} |> Terminal.changeset(attrs) |> Repo.insert()
  end

  def update_terminal(%Terminal{} = terminal, attrs) do
    terminal |> Terminal.changeset(attrs) |> Repo.update()
  end

  def delete_terminal(%Terminal{} = terminal), do: Repo.delete(terminal)

  def change_terminal(%Terminal{} = terminal, attrs \\ %{}), do: Terminal.changeset(terminal, attrs)


  @doc """
  Returns the list of buses.
  
  ## Examples
  
      iex> list_buses()
      [%Bus{}, ...]
  
  """
  def list_buses(opts \\ []) do
    Bus
    |> maybe_filter_bus_organisation(opts[:organisation_id])
    |> Repo.all()
  end
  
  @doc """
  Gets a single bus.
  
  Raises `Ecto.NoResultsError` if the Bus does not exist.
  
  ## Examples
  
      iex> get_bus!(123)
      %Bus{}
      
      iex> get_bus!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_bus!(id), do: Repo.get!(Bus, id)
  
  @doc """
  Gets a single bus.
  
  Returns nil if the Bus does not exist.
  
  ## Examples
  
      iex> get_bus(123)
      %Bus{}
      
      iex> get_bus(456)
      nil
  
  """
  def get_bus(id), do: Repo.get(Bus, id)
  
  @doc """
  Gets a bus by registration number.
  
  Returns nil if no bus is found with the given registration number.
  
  ## Examples
  
      iex> get_bus_by_registration_number("ABC123")
      %Bus{}
      
      iex> get_bus_by_registration_number("NOT_EXISTS")
      nil
  
  """
  def get_bus_by_registration_number(registration_number) do
    Repo.get_by(Bus, registration_number: registration_number)
  end
  
  @doc """
  Creates a bus.
  
  ## Examples
  
      iex> create_bus(%{field: value})
      {:ok, %Bus{}}
      
      iex> create_bus(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def create_bus(attrs \\ %{}) do
    %Bus{}
    |> Bus.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates a bus.
  
  ## Examples
  
      iex> update_bus(bus, %{field: new_value})
      {:ok, %Bus{}}
      
      iex> update_bus(bus, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def update_bus(%Bus{} = bus, attrs) do
    bus
    |> Bus.changeset(attrs)
    |> Repo.update()
  end
  
  @doc """
  Deletes a bus.
  
  ## Examples
  
      iex> delete_bus(bus)
      {:ok, %Bus{}}
      
      iex> delete_bus(bus)
      {:error, %Ecto.Changeset{}}
  
  """
  def delete_bus(%Bus{} = bus) do
    Repo.delete(bus)
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bus changes.
  
  ## Examples
  
      iex> change_bus(bus)
      %Ecto.Changeset{data: %Bus{}}
  
  """
  def change_bus(%Bus{} = bus, attrs \\ %{}) do
    Bus.changeset(bus, attrs)
  end
  
  @doc """
  Returns the list of buses with a specific status.
  
  ## Examples
  
      iex> list_buses_by_status("active")
      [%Bus{}, ...]
  
  """
  def list_buses_by_status(status, opts \\ []) do
    from(b in Bus, where: b.status == ^status, order_by: [desc: b.inserted_at])
    |> maybe_filter_bus_organisation(opts[:organisation_id])
    |> Repo.all()
  end
  
  @doc """
  Returns the list of buses manufactured in a specific year range.
  
  ## Examples
  
      iex> list_buses_by_year_range(2010, 2020)
      [%Bus{}, ...]
  
  """
  def list_buses_by_year_range(start_year, end_year) do
    query = from b in Bus,
            where: b.year >= ^start_year and b.year <= ^end_year,
            order_by: [asc: b.year]
    Repo.all(query)
  end
  
  @doc """
  Returns the total count of buses.
  
  ## Examples
  
      iex> count_buses()
      12
  
  """
  def count_buses do
    Repo.aggregate(Bus, :count, :id)
  end

  # ── Vehicles (unified fleet: buses + trucks) ──────────────────────────────

  alias FleetMint.Transport.Fleet.{Vehicle, BusProfile, TruckProfile}

  def list_vehicles(opts \\ []) do
    from(v in Vehicle, where: is_nil(v.archived_at))
    |> maybe_filter_vehicle_type(opts[:type])
    |> maybe_filter_vehicle_status(opts[:status])
    |> maybe_filter_vehicle_organisation(opts[:organisation_id])
    |> preload([:bus_profile, :truck_profile, :current_driver])
    |> order_by([v], v.registration_number)
    |> Repo.all()
  end

  def list_buses_v2(opts \\ []), do: list_vehicles(Keyword.put(opts, :type, "bus"))
  def list_trucks(opts \\ []), do: list_vehicles(Keyword.put(opts, :type, "truck"))

  def get_vehicle!(id) do
    Repo.get!(Vehicle, id)
    |> Repo.preload([:bus_profile, :truck_profile, :current_driver])
  end

  def create_vehicle(attrs) do
    Repo.transaction(fn ->
      vehicle = %Vehicle{} |> Vehicle.changeset(attrs) |> Repo.insert!()
      case vehicle.vehicle_type do
        "bus" ->
          profile_attrs = Map.get(attrs, "bus_profile", %{}) |> Map.put("vehicle_id", vehicle.id)
          %BusProfile{} |> BusProfile.changeset(profile_attrs) |> Repo.insert!()
        "truck" ->
          profile_attrs = Map.get(attrs, "truck_profile", %{}) |> Map.put("vehicle_id", vehicle.id)
          %TruckProfile{} |> TruckProfile.changeset(profile_attrs) |> Repo.insert!()
      end
      Repo.preload(vehicle, [:bus_profile, :truck_profile])
    end)
  end

  def update_vehicle(%Vehicle{} = vehicle, attrs) do
    Repo.transaction(fn ->
      vehicle = vehicle |> Vehicle.changeset(attrs) |> Repo.update!()
      case vehicle.vehicle_type do
        "bus" ->
          profile = vehicle.bus_profile || %BusProfile{}
          profile_attrs = Map.get(attrs, "bus_profile", %{}) |> Map.put("vehicle_id", vehicle.id)
          profile |> BusProfile.changeset(profile_attrs) |> Repo.insert_or_update!()
        "truck" ->
          profile = vehicle.truck_profile || %TruckProfile{}
          profile_attrs = Map.get(attrs, "truck_profile", %{}) |> Map.put("vehicle_id", vehicle.id)
          profile |> TruckProfile.changeset(profile_attrs) |> Repo.insert_or_update!()
      end
      Repo.preload(vehicle, [:bus_profile, :truck_profile])
    end)
  end

  def delete_vehicle(%Vehicle{} = vehicle) do
    vehicle
    |> Ecto.Changeset.change(archived_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update()
  end

  def change_vehicle(%Vehicle{} = vehicle, attrs \\ %{}) do
    Vehicle.changeset(vehicle, attrs)
  end

  def vehicles_count_by_type do
    from(v in Vehicle,
      group_by: v.vehicle_type,
      select: {v.vehicle_type, count(v.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  def active_vehicle_count, do: Repo.aggregate(from(v in Vehicle, where: v.status == "active"), :count)

  defp maybe_filter_vehicle_type(query, nil), do: query
  defp maybe_filter_vehicle_type(query, type), do: where(query, [v], v.vehicle_type == ^type)

  defp maybe_filter_vehicle_status(query, nil), do: query
  defp maybe_filter_vehicle_status(query, status), do: where(query, [v], v.status == ^status)

  defp maybe_filter_vehicle_organisation(query, nil), do: query
  defp maybe_filter_vehicle_organisation(query, :all), do: query
  defp maybe_filter_vehicle_organisation(query, organisation_id), do: where(query, [v], v.organisation_id == ^organisation_id)

  defp maybe_filter_bus_organisation(query, nil), do: query
  defp maybe_filter_bus_organisation(query, :all), do: query
  defp maybe_filter_bus_organisation(query, organisation_id), do: where(query, [b], b.organisation_id == ^organisation_id)

  # ── Vehicle Maintenance ────────────────────────────────────────────────────

  alias FleetMint.Transport.Fleet.VehicleMaintenance

  def list_maintenances do
    VehicleMaintenance
    |> order_by([m], desc: m.service_date)
    |> preload([:vehicle, :recorded_by])
    |> Repo.all()
  end

  def list_maintenances_for_vehicle(vehicle_id) do
    from(m in VehicleMaintenance, where: m.vehicle_id == ^vehicle_id,
      order_by: [desc: m.service_date], preload: [:vehicle, :recorded_by])
    |> Repo.all()
  end

  def get_maintenance!(id) do
    VehicleMaintenance |> preload([:vehicle, :recorded_by]) |> Repo.get!(id)
  end

  def create_maintenance(attrs \\ %{}) do
    changeset = VehicleMaintenance.changeset(%VehicleMaintenance{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:maintenance, changeset)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{maintenance: m} ->
      maybe_record_amount("expense", "VehicleMaintenance", m.id, m.cost, "#{m.service_type} on #{m.service_date}")
    end)
    |> Repo.transaction()
    |> unwrap_multi(:maintenance)
  end

  def update_maintenance(%VehicleMaintenance{} = m, attrs) do
    changeset = VehicleMaintenance.changeset(m, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:maintenance, changeset)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{maintenance: updated} ->
      sync_amount("expense", "VehicleMaintenance", updated.id, updated.cost, "#{updated.service_type} on #{updated.service_date}")
    end)
    |> Repo.transaction()
    |> unwrap_multi(:maintenance)
  end

  def delete_maintenance(%VehicleMaintenance{} = m), do: Repo.delete(m)

  def change_maintenance(%VehicleMaintenance{} = m, attrs \\ %{}),
    do: VehicleMaintenance.changeset(m, attrs)

  # ── Fuel Logs ──────────────────────────────────────────────────────────────

  alias FleetMint.Transport.Fleet.FuelLog

  def list_fuel_logs do
    FuelLog
    |> order_by([f], desc: f.log_date)
    |> preload([:vehicle, :driver])
    |> Repo.all()
  end

  def list_fuel_logs_for_vehicle(vehicle_id) do
    from(f in FuelLog, where: f.vehicle_id == ^vehicle_id,
      order_by: [desc: f.log_date], preload: [:vehicle, :driver])
    |> Repo.all()
  end

  def get_fuel_log!(id) do
    FuelLog |> preload([:vehicle, :driver]) |> Repo.get!(id)
  end

  def create_fuel_log(attrs \\ %{}) do
    changeset = FuelLog.changeset(%FuelLog{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:fuel_log, changeset)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{fuel_log: log} ->
      maybe_record_amount("expense", "FuelLog", log.id, log.total_cost, "Fuel log on #{log.log_date}")
    end)
    |> Repo.transaction()
    |> unwrap_multi(:fuel_log)
  end

  def update_fuel_log(%FuelLog{} = log, attrs) do
    changeset = FuelLog.changeset(log, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:fuel_log, changeset)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{fuel_log: updated} ->
      sync_amount("expense", "FuelLog", updated.id, updated.total_cost, "Fuel log on #{updated.log_date}")
    end)
    |> Repo.transaction()
    |> unwrap_multi(:fuel_log)
  end

  def delete_fuel_log(%FuelLog{} = log), do: Repo.delete(log)

  def change_fuel_log(%FuelLog{} = log, attrs \\ %{}), do: FuelLog.changeset(log, attrs)

  def total_fuel_cost_for_vehicle(vehicle_id) do
    Repo.aggregate(from(f in FuelLog, where: f.vehicle_id == ^vehicle_id), :sum, :total_cost)
    |> Kernel.||(Decimal.new(0))
  end

  def fuel_cost_today do
    today = Date.utc_today()
    Repo.aggregate(from(f in FuelLog, where: f.log_date == ^today), :sum, :total_cost)
    |> Kernel.||(Decimal.new(0))
  end

  def count_pending_maintenances do
    Repo.aggregate(from(m in VehicleMaintenance, where: m.status in ["scheduled", "in_progress"]), :count)
  end

  def count_vehicles do
    Repo.aggregate(Vehicle, :count, :id)
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
