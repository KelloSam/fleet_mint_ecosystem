defmodule FleetMintWeb.VehicleMaintenanceControllerTest do
  use FleetMintWeb.ConnCase
  import Ecto.Query

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      vehicle_a = vehicle_fixture(%{"organisation_id" => org_a.organisation_id})
      vehicle_b = vehicle_fixture(%{"organisation_id" => org_b.organisation_id})

      maintenance_a = maintenance_fixture(vehicle: vehicle_a)
      maintenance_b = maintenance_fixture(vehicle: vehicle_b)

      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)
      manager_a = user_fixture(role: "manager", organisation_id: org_a.organisation_id)

      %{
        org_a: org_a,
        org_b: org_b,
        vehicle_a: vehicle_a,
        vehicle_b: vehicle_b,
        maintenance_a: maintenance_a,
        maintenance_b: maintenance_b,
        staff_a: staff_a,
        manager_a: manager_a
      }
    end

    test "index only lists the caller's own organisation's maintenance records", %{
      conn: conn,
      staff_a: staff_a,
      maintenance_a: maintenance_a,
      maintenance_b: maintenance_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/maintenances")
      response = html_response(conn, 200)

      assert response =~ "maintenances/#{maintenance_a.id}\""
      refute response =~ "maintenances/#{maintenance_b.id}\""
    end

    test "prohibited: cannot view another organisation's maintenance record", %{
      conn: conn,
      staff_a: staff_a,
      maintenance_b: maintenance_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/maintenances/#{maintenance_b}")

      assert redirected_to(conn) == ~p"/maintenances"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: cannot update another organisation's maintenance record", %{
      conn: conn,
      manager_a: manager_a,
      maintenance_b: maintenance_b
    } do
      conn =
        conn
        |> log_in_user(manager_a)
        |> put(~p"/maintenances/#{maintenance_b}", %{
          "vehicle_maintenance" => %{"cost" => "9999"}
        })

      assert redirected_to(conn) == ~p"/maintenances"
      assert FleetMint.Repo.reload!(maintenance_b).cost == maintenance_b.cost
    end

    test "prohibited: cannot delete another organisation's maintenance record", %{
      conn: conn,
      manager_a: manager_a,
      maintenance_b: maintenance_b
    } do
      conn = conn |> log_in_user(manager_a) |> delete(~p"/maintenances/#{maintenance_b}")

      assert redirected_to(conn) == ~p"/maintenances"
      assert FleetMint.Repo.reload(maintenance_b)
    end

    test "prohibited: cannot create a maintenance record against another organisation's vehicle",
         %{conn: conn, manager_a: manager_a, vehicle_b: vehicle_b} do
      count_before =
        FleetMint.Repo.aggregate(
          where(FleetMint.Transport.Fleet.VehicleMaintenance,
            vehicle_id: ^vehicle_b.id
          ),
          :count
        )

      conn =
        conn
        |> log_in_user(manager_a)
        |> post(~p"/maintenances", %{
          "vehicle_maintenance" => %{
            "service_date" => Date.to_iso8601(Date.utc_today()),
            "service_type" => "oil_change",
            "vehicle_id" => vehicle_b.id
          }
        })

      assert html_response(conn, 200) =~ "not available to you"

      assert count_before ==
               FleetMint.Repo.aggregate(
                 where(FleetMint.Transport.Fleet.VehicleMaintenance,
                   vehicle_id: ^vehicle_b.id
                 ),
                 :count
               )
    end
  end
end
