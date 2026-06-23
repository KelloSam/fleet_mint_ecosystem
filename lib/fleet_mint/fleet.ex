defmodule FleetMint.Fleet do
  @moduledoc """
  The Fleet context.
  
  This context handles operations related to buses and routes management.
  It provides functions to create, read, update, and delete buses and routes,
  as well as more specialized functions for fleet management operations.
  """
  
  import Ecto.Query, warn: false
  alias FleetMint.Repo

  alias FleetMint.Fleet.{Bus, Operator}

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

  def get_operator_with_routes!(id) do
    Operator
    |> Repo.get!(id)
    |> Repo.preload(routes: from(r in FleetMint.Fleet.Route, order_by: r.name))
  end

  def list_operators_with_route_counts do
    from(o in Operator,
      where: is_nil(o.archived_at),
      left_join: or_ in "operator_routes", on: or_.operator_id == o.id,
      group_by: o.id,
      select: %{o | schedule_count: count(or_.route_id)},
      order_by: o.name
    ) |> Repo.all()
  end

  def add_route_to_operator(%Operator{} = op, %FleetMint.Fleet.Route{} = route) do
    Repo.insert_all("operator_routes",
      [%{operator_id: op.id, route_id: route.id}],
      on_conflict: :nothing)
  end

  def create_operator(attrs \\ %{}) do
    %Operator{} |> Operator.changeset(attrs) |> Repo.insert()
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
  
  @doc """
  Returns the list of buses.
  
  ## Examples
  
      iex> list_buses()
      [%Bus{}, ...]
  
  """
  def list_buses do
    Repo.all(Bus)
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
  def list_buses_by_status(status) do
    query = from b in Bus,
            where: b.status == ^status,
            order_by: [desc: b.inserted_at]
    Repo.all(query)
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
  
  alias FleetMint.Fleet.Route
  
  @doc """
  Returns the list of routes.
  
  ## Examples
  
      iex> list_routes()
      [%Route{}, ...]
  
  """
  def list_routes do
    from(r in Route, where: is_nil(r.archived_at), order_by: r.name) |> Repo.all()
  end
  
  @doc """
  Gets a single route.
  
  Raises `Ecto.NoResultsError` if the Route does not exist.
  
  ## Examples
  
      iex> get_route!(123)
      %Route{}
      
      iex> get_route!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_route!(id), do: Repo.get!(Route, id)
  
  @doc """
  Gets a single route.
  
  Returns nil if the Route does not exist.
  
  ## Examples
  
      iex> get_route(123)
      %Route{}
      
      iex> get_route(456)
      nil
  
  """
  def get_route(id), do: Repo.get(Route, id)
  
  @doc """
  Gets a route by name.
  
  Returns nil if no route is found with the given name.
  
  ## Examples
  
      iex> get_route_by_name("City Express")
      %Route{}
      
      iex> get_route_by_name("NOT_EXISTS")
      nil
  
  """
  def get_route_by_name(name) do
    Repo.get_by(Route, name: name)
  end
  
  @doc """
  Creates a route.
  
  ## Examples
  
      iex> create_route(%{field: value})
      {:ok, %Route{}}
      
      iex> create_route(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def create_route(attrs \\ %{}) do
    %Route{}
    |> Route.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates a route.
  
  ## Examples
  
      iex> update_route(route, %{field: new_value})
      {:ok, %Route{}}
      
      iex> update_route(route, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def update_route(%Route{} = route, attrs) do
    route
    |> Route.changeset(attrs)
    |> Repo.update()
  end
  
  @doc """
  Deletes a route.
  
  ## Examples
  
      iex> delete_route(route)
      {:ok, %Route{}}
      
      iex> delete_route(route)
      {:error, %Ecto.Changeset{}}
  
  """
  def delete_route(%Route{} = route) do
    route
    |> Ecto.Changeset.change(archived_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update()
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking route changes.
  
  ## Examples
  
      iex> change_route(route)
      %Ecto.Changeset{data: %Route{}}
  
  """
  def change_route(%Route{} = route, attrs \\ %{}) do
    Route.changeset(route, attrs)
  end
  
  @doc """
  Returns the list of routes with a specific status.
  
  ## Examples
  
      iex> list_routes_by_status("active")
      [%Route{}, ...]
  
  """
  def list_routes_by_status(status) do
    from(r in Route, where: r.status == ^status and is_nil(r.archived_at), order_by: [desc: r.inserted_at])
    |> Repo.all()
  end
  
  @doc """
  Returns the list of routes that start at a specific location.
  
  ## Examples
  
      iex> list_routes_by_start_location("Downtown")
      [%Route{}, ...]
  
  """
  def list_routes_by_start_location(location) do
    from(r in Route, where: r.start_location == ^location and is_nil(r.archived_at), order_by: [asc: r.name])
    |> Repo.all()
  end
  
  @doc """
  Returns the list of routes that end at a specific location.
  
  ## Examples
  
      iex> list_routes_by_end_location("Airport")
      [%Route{}, ...]
  
  """
  def list_routes_by_end_location(location) do
    from(r in Route, where: r.end_location == ^location and is_nil(r.archived_at), order_by: [asc: r.name])
    |> Repo.all()
  end
  
  @doc """
  Returns routes that contain a specific location (either as start or end).
  
  ## Examples
  
      iex> list_routes_by_location("Mall")
      [%Route{}, ...]
  
  """
  def list_routes_by_location(location) do
    from(r in Route,
      where: (r.start_location == ^location or r.end_location == ^location) and is_nil(r.archived_at),
      order_by: [asc: r.name]
    ) |> Repo.all()
  end
  
  @doc """
  Returns routes within a specific fare range.
  
  ## Examples
  
      iex> list_routes_by_fare_range(10.00, 20.00)
      [%Route{}, ...]
  
  """
  def list_routes_by_fare_range(min_fare, max_fare) do
    from(r in Route,
      where: r.fare >= ^min_fare and r.fare <= ^max_fare and is_nil(r.archived_at),
      order_by: [asc: r.fare]
    ) |> Repo.all()
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
  
  @doc """
  Returns the total count of routes.
  
  ## Examples
  
      iex> count_routes()
      8
  
  """
  def count_routes do
    Repo.aggregate(Route, :count, :id)
  end

  # ── Vehicles (unified fleet: buses + trucks) ──────────────────────────────

  alias FleetMint.Fleet.{Vehicle, BusProfile, TruckProfile}

  def list_vehicles(opts \\ []) do
    from(v in Vehicle, where: is_nil(v.archived_at))
    |> maybe_filter_vehicle_type(opts[:type])
    |> maybe_filter_vehicle_status(opts[:status])
    |> preload([:bus_profile, :truck_profile, :current_driver])
    |> order_by([v], v.registration_number)
    |> Repo.all()
  end

  def list_buses_v2, do: list_vehicles(type: "bus")
  def list_trucks, do: list_vehicles(type: "truck")

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

  # ── Vehicle Maintenance ────────────────────────────────────────────────────

  alias FleetMint.Fleet.VehicleMaintenance

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
    %VehicleMaintenance{} |> VehicleMaintenance.changeset(attrs) |> Repo.insert()
  end

  def update_maintenance(%VehicleMaintenance{} = m, attrs) do
    m |> VehicleMaintenance.changeset(attrs) |> Repo.update()
  end

  def delete_maintenance(%VehicleMaintenance{} = m), do: Repo.delete(m)

  def change_maintenance(%VehicleMaintenance{} = m, attrs \\ %{}),
    do: VehicleMaintenance.changeset(m, attrs)

  # ── Fuel Logs ──────────────────────────────────────────────────────────────

  alias FleetMint.Fleet.FuelLog

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
    %FuelLog{} |> FuelLog.changeset(attrs) |> Repo.insert()
  end

  def update_fuel_log(%FuelLog{} = log, attrs) do
    log |> FuelLog.changeset(attrs) |> Repo.update()
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
end
