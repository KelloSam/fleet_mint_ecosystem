defmodule FleetMintWeb.CashingReportTripMatchControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.TicketingFixtures
  import FleetMint.FinanceFixtures
  import FleetMint.IdentityFixtures

  alias FleetMint.Transport.Trips

  describe "trip matching UI" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      vehicle_a = vehicle_fixture()
      _bus_a = bus_fixture(organisation_id: org_a.organisation_id, vehicle_id: vehicle_a.id)
      schedule_a = schedule_fixture(operator_id: org_a.id, vehicle_id: vehicle_a.id)
      {:ok, trip_a} = Trips.get_or_create_trip(schedule_a.id, ~D[2026-08-01])

      schedule_b = schedule_fixture(operator_id: org_b.id)
      {:ok, trip_b} = Trips.get_or_create_trip(schedule_b.id, ~D[2026-08-01])

      # A bus in org_a whose vehicle has never been scheduled — guaranteed
      # unmappable by the automatic matcher, so it lands in the queue.
      unmatched_vehicle = vehicle_fixture()
      unmatched_bus = bus_fixture(organisation_id: org_a.organisation_id, vehicle_id: unmatched_vehicle.id)
      unmatched_report = cashing_report_fixture(%{bus_id: unmatched_bus.id, report_date: ~D[2026-08-01]})

      other_org_unmatched_bus = bus_fixture(organisation_id: org_b.organisation_id)
      other_org_unmatched_report = cashing_report_fixture(%{bus_id: other_org_unmatched_bus.id})

      admin_a = user_fixture(role: "tenant_admin", organisation_id: org_a.organisation_id)
      cashier_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)

      %{
        org_a: org_a,
        trip_a: trip_a,
        trip_b: trip_b,
        unmatched_report: unmatched_report,
        other_org_unmatched_report: other_org_unmatched_report,
        admin_a: admin_a,
        cashier_a: cashier_a
      }
    end

    test "authorised: admin's queue only lists their own organisation's unmatched reports", %{
      conn: conn,
      admin_a: admin_a,
      other_org_unmatched_report: other_org_unmatched_report
    } do
      conn = conn |> log_in_user(admin_a) |> get(~p"/cashing_reports/unmatched")
      html = html_response(conn, 200)

      assert html =~ "unmappable"
      refute html =~ "/cashing_reports/#{other_org_unmatched_report.id}/trip_match"
    end

    test "prohibited: a cashier cannot view the trip-match form", %{
      conn: conn,
      cashier_a: cashier_a,
      unmatched_report: unmatched_report
    } do
      conn = conn |> log_in_user(cashier_a) |> get(~p"/cashing_reports/#{unmatched_report}/trip_match")
      assert redirected_to(conn) == ~p"/cashing_reports"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not authorised"
    end

    test "prohibited: a cashier cannot submit a match", %{
      conn: conn,
      cashier_a: cashier_a,
      unmatched_report: unmatched_report,
      trip_a: trip_a
    } do
      conn =
        conn
        |> log_in_user(cashier_a)
        |> post(~p"/cashing_reports/#{unmatched_report}/trip_match", %{"trip_id" => trip_a.id})

      assert redirected_to(conn) == ~p"/cashing_reports"

      reloaded = FleetMint.Finance.get_cashing_report!(unmatched_report.id)
      assert reloaded.trip_mapping_status == "unmappable"
    end

    test "authorised: admin manually matches an unmappable report to a trip in their own organisation", %{
      conn: conn,
      admin_a: admin_a,
      unmatched_report: unmatched_report,
      trip_a: trip_a
    } do
      conn =
        conn
        |> log_in_user(admin_a)
        |> post(~p"/cashing_reports/#{unmatched_report}/trip_match", %{"trip_id" => trip_a.id})

      assert redirected_to(conn) == ~p"/cashing_reports/unmatched"

      reloaded = FleetMint.Finance.get_cashing_report!(unmatched_report.id)
      assert reloaded.trip_mapping_status == "manually_matched"

      assert [allocation] = FleetMint.Repo.all(FleetMint.Finance.CashingReportTrip)
      assert allocation.cashing_report_id == unmatched_report.id
      assert allocation.trip_id == trip_a.id
      assert allocation.match_method == "manual"
      assert allocation.matched_by_id == admin_a.id
    end

    test "prohibited: matching to a trip in a different organisation is rejected and writes nothing", %{
      conn: conn,
      admin_a: admin_a,
      unmatched_report: unmatched_report,
      trip_b: trip_b
    } do
      conn =
        conn
        |> log_in_user(admin_a)
        |> post(~p"/cashing_reports/#{unmatched_report}/trip_match", %{"trip_id" => trip_b.id})

      assert redirected_to(conn) == ~p"/cashing_reports/#{unmatched_report}/trip_match"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"

      reloaded = FleetMint.Finance.get_cashing_report!(unmatched_report.id)
      assert reloaded.trip_mapping_status == "unmappable"
      assert FleetMint.Repo.all(FleetMint.Finance.CashingReportTrip) == []
    end

    test "prohibited: an admin cannot view or match another organisation's report", %{
      conn: conn,
      admin_a: admin_a,
      other_org_unmatched_report: other_org_unmatched_report,
      trip_a: trip_a
    } do
      view_conn = conn |> log_in_user(admin_a) |> get(~p"/cashing_reports/#{other_org_unmatched_report}/trip_match")
      assert redirected_to(view_conn) == ~p"/cashing_reports/unmatched"

      match_conn =
        conn
        |> log_in_user(admin_a)
        |> post(~p"/cashing_reports/#{other_org_unmatched_report}/trip_match", %{"trip_id" => trip_a.id})

      assert redirected_to(match_conn) == ~p"/cashing_reports/unmatched"
      assert FleetMint.Repo.all(FleetMint.Finance.CashingReportTrip) == []
    end
  end
end
