defmodule FleetMintWeb.ReportControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.ReportsFixtures
  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures
  import FleetMint.FinanceFixtures, only: [cashing_report_fixture: 1]

  @create_attrs %{start_date: ~D[2025-03-03], end_date: ~D[2025-03-03]}
  @update_attrs %{start_date: ~D[2025-03-04], end_date: ~D[2025-03-04]}
  @invalid_attrs %{start_date: nil, end_date: nil}

  describe "index" do
    test "lists all reports", %{conn: conn} do
      conn = get(conn, ~p"/reports")
      assert html_response(conn, 200) =~ "Listing Reports"
    end
  end

  describe "new report" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/reports/new")
      assert html_response(conn, 200) =~ "New Report"
    end
  end

  describe "create report" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/reports", report: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/reports/#{id}"

      conn = get(conn, ~p"/reports/#{id}")
      assert html_response(conn, 200) =~ "Report #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/reports", report: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Report"
    end
  end

  describe "edit report" do
    setup [:create_report]

    test "renders form for editing chosen report", %{conn: conn, report: report} do
      conn = get(conn, ~p"/reports/#{report}/edit")
      assert html_response(conn, 200) =~ "Edit Report"
    end
  end

  describe "update report" do
    setup [:create_report]

    test "redirects when data is valid", %{conn: conn, report: report} do
      conn = put(conn, ~p"/reports/#{report}", report: @update_attrs)
      assert redirected_to(conn) == ~p"/reports/#{report}"

      conn = get(conn, ~p"/reports/#{report}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, report: report} do
      conn = put(conn, ~p"/reports/#{report}", report: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Report"
    end
  end

  describe "delete report" do
    setup [:create_report]

    test "deletes chosen report", %{conn: conn, report: report} do
      conn = delete(conn, ~p"/reports/#{report}")
      assert redirected_to(conn) == ~p"/reports"

      assert_error_sent 404, fn ->
        get(conn, ~p"/reports/#{report}")
      end
    end
  end

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(organisation_id: org_a.organisation_id)
      bus_b = bus_fixture(organisation_id: org_b.organisation_id)

      empty_report = report_fixture()
      own_org_report = report_fixture()
      cashing_report_fixture(report_id: own_org_report.id, bus_id: bus_a.id)

      other_org_report = report_fixture()
      cashing_report_fixture(report_id: other_org_report.id, bus_id: bus_b.id)

      manager_a = user_fixture(role: "manager", organisation_id: org_a.organisation_id)

      %{
        empty_report: empty_report,
        own_org_report: own_org_report,
        other_org_report: other_org_report,
        manager_a: manager_a
      }
    end

    test "authorised: can edit an empty report (nothing attached yet)", %{
      conn: conn,
      manager_a: manager_a,
      empty_report: empty_report
    } do
      conn = conn |> log_in_user(manager_a) |> get(~p"/reports/#{empty_report}/edit")
      assert html_response(conn, 200) =~ "Report"
    end

    test "authorised: can edit a report containing only their own organisation's cashing reports",
         %{conn: conn, manager_a: manager_a, own_org_report: own_org_report} do
      conn = conn |> log_in_user(manager_a) |> get(~p"/reports/#{own_org_report}/edit")
      assert html_response(conn, 200) =~ "Report"
    end

    test "prohibited: cannot edit a report containing another organisation's cashing reports",
         %{conn: conn, manager_a: manager_a, other_org_report: other_org_report} do
      conn = conn |> log_in_user(manager_a) |> get(~p"/reports/#{other_org_report}/edit")

      assert redirected_to(conn) == ~p"/reports"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: cannot delete a report containing another organisation's cashing reports",
         %{conn: conn, manager_a: manager_a, other_org_report: other_org_report} do
      conn = conn |> log_in_user(manager_a) |> delete(~p"/reports/#{other_org_report}")

      assert redirected_to(conn) == ~p"/reports"
      assert FleetMint.Repo.reload(other_org_report)
    end

    test "prohibited: cannot update a report containing another organisation's cashing reports",
         %{conn: conn, manager_a: manager_a, other_org_report: other_org_report} do
      conn =
        conn
        |> log_in_user(manager_a)
        |> put(~p"/reports/#{other_org_report}", %{
          "report" => %{"start_date" => "2025-01-01", "end_date" => "2025-01-07"}
        })

      assert redirected_to(conn) == ~p"/reports"

      assert FleetMint.Repo.reload!(other_org_report).start_date ==
               other_org_report.start_date
    end
  end

  defp create_report(_) do
    report = report_fixture()
    %{report: report}
  end
end
