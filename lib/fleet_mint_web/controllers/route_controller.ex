defmodule FleetMintWeb.RouteController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Routes
  alias FleetMint.Transport.Routes.Route

  plug :require_admin when action in [:new, :create, :edit, :update, :delete]

  defp require_admin(conn, _opts) do
    if FleetMint.Identity.Authorization.authorized?(conn.assigns.current_user, ["admin", "manager"]) do
      conn
    else
      conn
      |> put_flash(:error, "Only admins and managers can modify routes.")
      |> redirect(to: ~p"/routes")
      |> halt()
    end
  end

  def index(conn, params) do
    status = Map.get(params, "status")
    routes = if status && status != "", do: Routes.list_routes_by_status(status), else: Routes.list_routes()
    render(conn, :index, routes: routes, filter_status: status || "")
  end

  def new(conn, _params) do
    changeset = Routes.change_route(%Route{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"route" => route_params}) do
    case Routes.create_route(route_params) do
      {:ok, route} ->
        conn
        |> put_flash(:info, "Route \"#{route.name}\" created successfully.")
        |> redirect(to: ~p"/routes/#{route}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    route = Routes.get_route!(id)
    render(conn, :show, route: route)
  end

  def edit(conn, %{"id" => id}) do
    route = Routes.get_route!(id)
    changeset = Routes.change_route(route)
    render(conn, :edit, route: route, changeset: changeset)
  end

  def update(conn, %{"id" => id, "route" => route_params}) do
    route = Routes.get_route!(id)

    case Routes.update_route(route, route_params) do
      {:ok, route} ->
        conn
        |> put_flash(:info, "Route \"#{route.name}\" updated successfully.")
        |> redirect(to: ~p"/routes/#{route}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, route: route, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    route = Routes.get_route!(id)
    {:ok, _route} = Routes.delete_route(route)

    conn
    |> put_flash(:info, "Route \"#{route.name}\" archived.")
    |> redirect(to: ~p"/routes")
  end
end
