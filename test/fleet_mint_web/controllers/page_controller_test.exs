defmodule FleetMintWeb.PageControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.FinanceFixtures
  import FleetMint.IdentityFixtures

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200) =~
             "Fleet management, passenger transit &amp; freight — all in one platform."
  end

  describe "dashboard: aggregates are tenant-scoped" do
    test "an organisation's dashboard excludes another organisation's fleet count and revenue, even when they share the same weekly report bucket",
         %{conn: conn} do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(%{organisation_id: org_a.organisation_id})
      bus_b = bus_fixture(%{organisation_id: org_b.organisation_id})

      # A weekly report has no organisation of its own — both organisations'
      # cashing reports can legitimately share one. The trend must still
      # attribute only bus_a's cashing report to org_a. A distinct date
      # range identifies this report against cashing_report_fixture/1's
      # own throwaway inner report (it always creates one, even though its
      # id gets overridden below).
      report = report_fixture(%{start_date: ~D[2026-01-05], end_date: ~D[2026-01-12]})

      cashing_report_fixture(%{
        report_id: report.id,
        bus_id: bus_a.id,
        received_cashing: "5555.00"
      })

      cashing_report_fixture(%{
        report_id: report.id,
        bus_id: bus_b.id,
        received_cashing: "9999.00"
      })

      tenant_admin_a = user_fixture(role: "tenant_admin", organisation_id: org_a.organisation_id)

      conn = conn |> log_in_user(tenant_admin_a) |> get(~p"/dashboard")
      html = html_response(conn, 200)

      assert conn.assigns.total_buses == 1

      trend_point =
        Enum.find(conn.assigns.weekly_revenue_trend, &(&1.start_date == ~D[2026-01-05]))

      assert Decimal.equal?(trend_point.revenue, Decimal.new("5555.00"))

      refute html =~ "9,999.00"
    end

    test "a platform_admin's dashboard includes every organisation's totals", %{conn: conn} do
      org_a = operator_fixture()
      org_b = operator_fixture()
      bus_fixture(%{organisation_id: org_a.organisation_id})
      bus_fixture(%{organisation_id: org_b.organisation_id})

      platform_admin = user_fixture(organisation_id: nil)

      conn = conn |> log_in_user(platform_admin) |> get(~p"/dashboard")

      assert html_response(conn, 200)
      assert conn.assigns.total_buses >= 2
    end
  end
end
