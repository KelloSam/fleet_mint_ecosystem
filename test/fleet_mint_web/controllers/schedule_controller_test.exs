defmodule FleetMintWeb.ScheduleControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant scoping" do
    test "new schedule form only offers the caller's own organisation's operator" do
      org_a = operator_fixture()
      org_b = operator_fixture()
      manager_a = user_fixture(role: "manager", organisation_id: org_a.organisation_id)

      conn = build_conn() |> log_in_user(manager_a) |> get(~p"/schedules/new")
      html_response(conn, 200)

      operator_ids = Enum.map(conn.assigns.operators, & &1.id)
      assert org_a.id in operator_ids
      refute org_b.id in operator_ids
    end
  end
end
