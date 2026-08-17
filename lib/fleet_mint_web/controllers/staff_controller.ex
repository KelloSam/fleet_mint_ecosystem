defmodule FleetMintWeb.StaffController do
  use FleetMintWeb, :controller

  alias FleetMint.Identity.Users

  def on_duty(conn, _params) do
    on_duty = Users.list_on_duty_staff(organisation_id: conn.assigns.organisation_scope)

    render(conn, :on_duty, on_duty: on_duty)
  end
end
