defmodule FleetMintWeb.PdfReportControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FinanceFixtures
  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(organisation_id: org_a.organisation_id)
      bus_b = bus_fixture(organisation_id: org_b.organisation_id)

      cashing_report_b = cashing_report_fixture(%{bus_id: bus_b.id})
      other_org_report = report_fixture()
      cashing_report_fixture(%{bus_id: bus_b.id, report_id: other_org_report.id})

      manager_a = user_fixture(role: "manager", organisation_id: org_a.organisation_id)

      %{
        bus_a: bus_a,
        cashing_report_b: cashing_report_b,
        other_org_report: other_org_report,
        manager_a: manager_a
      }
    end

    test "prohibited: cannot download the receipt for another organisation's cashing report",
         %{conn: conn, manager_a: manager_a, cashing_report_b: cashing_report_b} do
      conn = conn |> log_in_user(manager_a) |> get(~p"/pdf/receipt/#{cashing_report_b}")

      assert redirected_to(conn) == ~p"/admin/reports"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: cannot download the weekly PDF for a report containing another organisation's cashing reports",
         %{conn: conn, manager_a: manager_a, other_org_report: other_org_report} do
      conn = conn |> log_in_user(manager_a) |> get(~p"/pdf/weekly/#{other_org_report}")

      assert redirected_to(conn) == ~p"/admin/reports"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end
  end
end
