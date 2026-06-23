defmodule FleetMintWeb.Plugs.RequireRolePlug do
  import Plug.Conn
  import Phoenix.Controller
  use FleetMintWeb, :verified_routes

  def init(opts), do: opts

  def call(conn, roles: allowed_roles) do
    user = conn.assigns.current_user
    if user.role in allowed_roles do
      conn
    else
      conn
      |> put_flash(:error, "You don't have permission to access that page.")
      |> redirect(to: ~p"/dashboard")
      |> halt()
    end
  end
end
