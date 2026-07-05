defmodule FleetMintWeb.Plugs.RequireRolePlug do
  import Plug.Conn
  import Phoenix.Controller
  use FleetMintWeb, :verified_routes

  alias FleetMint.Identity.Authorization

  def init(opts), do: opts

  def call(conn, roles: allowed_roles) do
    user = conn.assigns.current_user
    if Authorization.authorized?(user, allowed_roles) do
      conn
    else
      conn
      |> put_flash(:error, "You don't have permission to access that page.")
      |> redirect(to: ~p"/dashboard")
      |> halt()
    end
  end
end
