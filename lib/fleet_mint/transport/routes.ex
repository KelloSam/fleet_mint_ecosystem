defmodule FleetMint.Transport.Routes do
  @moduledoc """
  The Routes context.

  A route is network/geography data (where a road runs, its stops, its
  base fare) that exists independently of any vehicle being assigned to
  run it — that assignment lives in `Transport.Fleet` and `Transport.Trips`.
  This context also owns `operator_routes`, the join between routes and
  the operators (bus companies) that run them.
  """

  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Transport.Fleet.Operator
  alias FleetMint.Transport.Routes.Route

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
  Returns the total count of routes.

  ## Examples

      iex> count_routes()
      8

  """
  def count_routes do
    Repo.aggregate(Route, :count, :id)
  end

  # ── operator_routes (operator <-> route join) ──────────────────────────────

  def get_operator_with_routes!(id) do
    Operator
    |> Repo.get!(id)
    |> Repo.preload(routes: from(r in Route, order_by: r.name))
  end

  def list_operators_with_route_counts(opts \\ []) do
    from(o in Operator,
      where: is_nil(o.archived_at),
      left_join: or_ in "operator_routes", on: or_.operator_id == o.id,
      group_by: o.id,
      select: %{o | schedule_count: count(or_.route_id)},
      order_by: o.name
    )
    |> maybe_filter_operator_organisation(opts[:organisation_id])
    |> Repo.all()
  end

  defp maybe_filter_operator_organisation(query, nil), do: query
  defp maybe_filter_operator_organisation(query, :all), do: query
  defp maybe_filter_operator_organisation(query, organisation_id) do
    where(query, [o], o.organisation_id == ^organisation_id)
  end

  def add_route_to_operator(%Operator{} = op, %Route{} = route) do
    Repo.insert_all("operator_routes",
      [%{operator_id: op.id, route_id: route.id}],
      on_conflict: :nothing)
  end
end
