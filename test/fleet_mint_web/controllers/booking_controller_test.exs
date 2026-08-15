defmodule FleetMintWeb.BookingControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures
  import FleetMint.TicketingFixtures

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

  describe "pickup terminal wiring" do
    test "authorised: booking a terminal within the caller's own organisation records and displays it" do
      org = operator_fixture()
      branch = branch_fixture(organisation_id: org.organisation_id)
      terminal = terminal_fixture(branch: branch)
      schedule = schedule_fixture(operator_id: org.id)
      cashier = user_fixture(role: "cashier", organisation_id: org.organisation_id)

      conn =
        build_conn()
        |> log_in_user(cashier)
        |> post(~p"/bookings", %{
          "booking" => %{
            "schedule_id" => schedule.id,
            "travel_date" => Date.to_iso8601(Date.utc_today()),
            "passenger_name" => "Jane Doe",
            "fare_paid" => "150.00",
            "terminal_id" => terminal.id
          }
        })

      booking =
        FleetMint.Transport.Ticketing.list_bookings()
        |> Enum.find(&(&1.passenger_name == "Jane Doe"))

      assert booking.terminal_id == terminal.id
      assert redirected_to(conn) == ~p"/bookings/#{booking}"

      show_conn = build_conn() |> log_in_user(cashier) |> get(~p"/bookings/#{booking}")
      assert html_response(show_conn, 200) =~ terminal.name
    end

    test "prohibited: booking a terminal from a different organisation is rejected" do
      org_a = operator_fixture()
      org_b = operator_fixture()
      branch_b = branch_fixture(organisation_id: org_b.organisation_id)
      terminal_b = terminal_fixture(branch: branch_b)
      schedule = schedule_fixture(operator_id: org_a.id)
      cashier_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)

      conn =
        build_conn()
        |> log_in_user(cashier_a)
        |> post(~p"/bookings", %{
          "booking" => %{
            "schedule_id" => schedule.id,
            "travel_date" => Date.to_iso8601(Date.utc_today()),
            "passenger_name" => "Jane Doe",
            "fare_paid" => "150.00",
            "terminal_id" => terminal_b.id
          }
        })

      assert html_response(conn, 200) =~ "not available to you"

      refute FleetMint.Transport.Ticketing.list_bookings()
             |> Enum.any?(&(&1.passenger_name == "Jane Doe"))
    end
  end
end
