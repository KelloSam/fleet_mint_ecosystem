defmodule BusCashingSystemWeb.ReportControllerTest do
  use BusCashingSystemWeb.ConnCase

  import BusCashingSystem.ReportsFixtures

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

  defp create_report(_) do
    report = report_fixture()
    %{report: report}
  end
end
