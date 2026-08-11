defmodule FleetMintWeb.BookingControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant scoping" do
    test "new booking form only offers the caller's own organisation's staff" do
      org_a = operator_fixture()
      org_b = operator_fixture()

      cashier_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)
      {:ok, cashier_a} = FleetMint.Identity.Users.update_user(cashier_a, %{phone: "0977000001"})

      cashier_b = user_fixture(role: "cashier", organisation_id: org_b.organisation_id)
      {:ok, cashier_b} = FleetMint.Identity.Users.update_user(cashier_b, %{phone: "0977000002"})

      conn = build_conn() |> log_in_user(cashier_a) |> get(~p"/bookings/new")
      html_response(conn, 200)

      staff_ids = Enum.map(conn.assigns.staff, & &1.id)
      assert cashier_a.id in staff_ids
      refute cashier_b.id in staff_ids
    end
  end
end
