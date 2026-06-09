defmodule FleetMintWeb.RouteController do
  use FleetMintWeb, :controller

  alias FleetMint.Fleet
  alias FleetMint.Fleet.Route

  def index(conn, params) do
    status = Map.get(params, "status")
    routes = if status && status != "", do: Fleet.list_routes_by_status(status), else: Fleet.list_routes()
    render(conn, :index, routes: routes, filter_status: status || "")
  end

  def new(conn, _params) do
    changeset = Fleet.change_route(%Route{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"route" => route_params}) do
    case Fleet.create_route(route_params) do
      {:ok, route} ->
        conn
        |> put_flash(:info, "Route \"#{route.name}\" created successfully.")
        |> redirect(to: ~p"/routes/#{route}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    route = Fleet.get_route!(id)
    render(conn, :show, route: route)
  end

  def edit(conn, %{"id" => id}) do
    route = Fleet.get_route!(id)
    changeset = Fleet.change_route(route)
    render(conn, :edit, route: route, changeset: changeset)
  end

  def update(conn, %{"id" => id, "route" => route_params}) do
    route = Fleet.get_route!(id)

    case Fleet.update_route(route, route_params) do
      {:ok, route} ->
        conn
        |> put_flash(:info, "Route \"#{route.name}\" updated successfully.")
        |> redirect(to: ~p"/routes/#{route}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, route: route, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    route = Fleet.get_route!(id)
    {:ok, _route} = Fleet.delete_route(route)

    conn
    |> put_flash(:info, "Route \"#{route.name}\" deleted.")
    |> redirect(to: ~p"/routes")
  end
end
