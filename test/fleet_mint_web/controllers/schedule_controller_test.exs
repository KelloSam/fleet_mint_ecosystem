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

    test "index only lists the caller's own organisation's schedules" do
      org_a = operator_fixture()
      org_b = operator_fixture()
      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)

      route = route_fixture(name: "Tenant Scoping Test Route")

      {:ok, schedule_a} =
        FleetMint.Transport.Trips.create_schedule(%{
          route_id: route.id,
          operator_id: org_a.id,
          departure_time: ~T[07:00:00],
          fare: "100.00"
        })

      {:ok, schedule_b} =
        FleetMint.Transport.Trips.create_schedule(%{
          route_id: route.id,
          operator_id: org_b.id,
          departure_time: ~T[08:00:00],
          fare: "100.00"
        })

      conn = build_conn() |> log_in_user(staff_a) |> get(~p"/schedules")
      response = html_response(conn, 200)

      assert response =~ schedule_a.schedule_code
      refute response =~ schedule_b.schedule_code
    end
  end
end
