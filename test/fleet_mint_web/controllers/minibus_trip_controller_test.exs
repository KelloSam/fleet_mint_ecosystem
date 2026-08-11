defmodule FleetMintWeb.MinibusTripControllerTest do
  use FleetMintWeb.ConnCase
  import Ecto.Query

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(organisation_id: org_a.organisation_id)
      bus_b = bus_fixture(organisation_id: org_b.organisation_id)

      trip_a = minibus_trip_fixture(bus: bus_a)
      trip_b = minibus_trip_fixture(bus: bus_b)

      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)

      %{
        org_a: org_a,
        org_b: org_b,
        bus_a: bus_a,
        bus_b: bus_b,
        trip_a: trip_a,
        trip_b: trip_b,
        staff_a: staff_a
      }
    end

    test "index only lists the caller's own organisation's trips", %{
      conn: conn,
      staff_a: staff_a,
      trip_a: trip_a,
      trip_b: trip_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/minibus_trips")
      response = html_response(conn, 200)

      assert response =~ "minibus_trips/#{trip_a.id}\""
      refute response =~ "minibus_trips/#{trip_b.id}\""
    end

    test "prohibited: cannot view another organisation's trip", %{
      conn: conn,
      staff_a: staff_a,
      trip_b: trip_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/minibus_trips/#{trip_b}")

      assert redirected_to(conn) == ~p"/minibus_trips"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: cannot update another organisation's trip", %{
      conn: conn,
      staff_a: staff_a,
      trip_b: trip_b
    } do
      conn =
        conn
        |> log_in_user(staff_a)
        |> put(~p"/minibus_trips/#{trip_b}", %{"minibus_trip" => %{"passengers_count" => "99"}})

      assert redirected_to(conn) == ~p"/minibus_trips"
      assert FleetMint.Repo.reload!(trip_b).passengers_count == trip_b.passengers_count
    end

    test "prohibited: cannot delete another organisation's trip", %{
      conn: conn,
      staff_a: staff_a,
      trip_b: trip_b
    } do
      conn = conn |> log_in_user(staff_a) |> delete(~p"/minibus_trips/#{trip_b}")

      assert redirected_to(conn) == ~p"/minibus_trips"
      assert FleetMint.Repo.reload(trip_b)
    end

    test "prohibited: cannot create a trip against another organisation's bus", %{
      conn: conn,
      staff_a: staff_a,
      bus_b: bus_b
    } do
      count_before =
        FleetMint.Repo.aggregate(
          where(FleetMint.Transport.Trips.MinibusTrip, bus_id: ^bus_b.id),
          :count
        )

      conn =
        conn
        |> log_in_user(staff_a)
        |> post(~p"/minibus_trips", %{
          "minibus_trip" => %{
            "date" => Date.to_iso8601(Date.utc_today()),
            "bus_id" => bus_b.id
          }
        })

      assert html_response(conn, 200) =~ "not available to you"

      assert count_before ==
               FleetMint.Repo.aggregate(
                 where(FleetMint.Transport.Trips.MinibusTrip, bus_id: ^bus_b.id),
                 :count
               )
    end
  end
end
