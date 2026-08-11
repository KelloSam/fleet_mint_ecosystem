defmodule FleetMintWeb.FuelLogControllerTest do
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

      fuel_log_a = fuel_log_fixture(vehicle: vehicle_a)
      fuel_log_b = fuel_log_fixture(vehicle: vehicle_b)

      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)

      %{
        org_a: org_a,
        org_b: org_b,
        vehicle_a: vehicle_a,
        vehicle_b: vehicle_b,
        fuel_log_a: fuel_log_a,
        fuel_log_b: fuel_log_b,
        staff_a: staff_a
      }
    end

    test "index only lists the caller's own organisation's fuel logs", %{
      conn: conn,
      staff_a: staff_a,
      fuel_log_a: fuel_log_a,
      fuel_log_b: fuel_log_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/fuel_logs")
      response = html_response(conn, 200)

      assert response =~ "fuel_logs/#{fuel_log_a.id}\""
      refute response =~ "fuel_logs/#{fuel_log_b.id}\""
    end

    test "prohibited: cannot view another organisation's fuel log", %{
      conn: conn,
      staff_a: staff_a,
      fuel_log_b: fuel_log_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/fuel_logs/#{fuel_log_b}")

      assert redirected_to(conn) == ~p"/fuel_logs"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: cannot update another organisation's fuel log", %{
      conn: conn,
      staff_a: staff_a,
      fuel_log_b: fuel_log_b
    } do
      conn =
        conn
        |> log_in_user(staff_a)
        |> put(~p"/fuel_logs/#{fuel_log_b}", %{"fuel_log" => %{"liters" => "999"}})

      assert redirected_to(conn) == ~p"/fuel_logs"
      assert Decimal.equal?(FleetMint.Repo.reload!(fuel_log_b).liters, fuel_log_b.liters)
    end

    test "prohibited: cannot delete another organisation's fuel log", %{
      conn: conn,
      staff_a: staff_a,
      fuel_log_b: fuel_log_b
    } do
      conn = conn |> log_in_user(staff_a) |> delete(~p"/fuel_logs/#{fuel_log_b}")

      assert redirected_to(conn) == ~p"/fuel_logs"
      assert FleetMint.Repo.reload(fuel_log_b)
    end

    test "prohibited: cannot create a fuel log against another organisation's vehicle", %{
      conn: conn,
      staff_a: staff_a,
      vehicle_b: vehicle_b
    } do
      count_before =
        FleetMint.Repo.aggregate(
          where(FleetMint.Transport.Fleet.FuelLog, vehicle_id: ^vehicle_b.id),
          :count
        )

      conn =
        conn
        |> log_in_user(staff_a)
        |> post(~p"/fuel_logs", %{
          "fuel_log" => %{
            "log_date" => Date.to_iso8601(Date.utc_today()),
            "liters" => "10",
            "vehicle_id" => vehicle_b.id
          }
        })

      assert html_response(conn, 200) =~ "not available to you"

      assert count_before ==
               FleetMint.Repo.aggregate(
                 where(FleetMint.Transport.Fleet.FuelLog, vehicle_id: ^vehicle_b.id),
                 :count
               )
    end
  end
end
