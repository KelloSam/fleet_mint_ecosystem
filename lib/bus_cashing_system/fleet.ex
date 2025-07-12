defmodule BusCashingSystem.Fleet do
  @moduledoc """
  The Fleet context.
  
  This context handles operations related to buses and routes management.
  It provides functions to create, read, update, and delete buses and routes,
  as well as more specialized functions for fleet management operations.
  """
  
  import Ecto.Query, warn: false
  alias BusCashingSystem.Repo
  
  alias BusCashingSystem.Fleet.Bus
  
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
  
  alias BusCashingSystem.Fleet.Route
  
  @doc """
  Returns the list of routes.
  
  ## Examples
  
      iex> list_routes()
      [%Route{}, ...]
  
  """
  def list_routes do
    Repo.all(Route)
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
    Repo.delete(route)
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
    query = from r in Route,
            where: r.status == ^status,
            order_by: [desc: r.inserted_at]
    Repo.all(query)
  end
  
  @doc """
  Returns the list of routes that start at a specific location.
  
  ## Examples
  
      iex> list_routes_by_start_location("Downtown")
      [%Route{}, ...]
  
  """
  def list_routes_by_start_location(location) do
    query = from r in Route,
            where: r.start_location == ^location,
            order_by: [asc: r.name]
    Repo.all(query)
  end
  
  @doc """
  Returns the list of routes that end at a specific location.
  
  ## Examples
  
      iex> list_routes_by_end_location("Airport")
      [%Route{}, ...]
  
  """
  def list_routes_by_end_location(location) do
    query = from r in Route,
            where: r.end_location == ^location,
            order_by: [asc: r.name]
    Repo.all(query)
  end
  
  @doc """
  Returns routes that contain a specific location (either as start or end).
  
  ## Examples
  
      iex> list_routes_by_location("Mall")
      [%Route{}, ...]
  
  """
  def list_routes_by_location(location) do
    query = from r in Route,
            where: r.start_location == ^location or r.end_location == ^location,
            order_by: [asc: r.name]
    Repo.all(query)
  end
  
  @doc """
  Returns routes within a specific fare range.
  
  ## Examples
  
      iex> list_routes_by_fare_range(10.00, 20.00)
      [%Route{}, ...]
  
  """
  def list_routes_by_fare_range(min_fare, max_fare) do
    query = from r in Route,
            where: r.fare >= ^min_fare and r.fare <= ^max_fare,
            order_by: [asc: r.fare]
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
  
  @doc """
  Returns the total count of routes.
  
  ## Examples
  
      iex> count_routes()
      8
  
  """
  def count_routes do
    Repo.aggregate(Route, :count, :id)
  end
end
