defmodule FleetMintWeb.CashingReportControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FinanceFixtures

  setup do
    report = report_fixture()
    {:ok, report: report}
  end

  @create_attrs %{
    description: "some description",
    days_worked: 42,
    expected_cashing: 120.5,
    received_cashing: 120.5,
    airtel_id: "some airtel_id",
    debt_balance: 120.5,
    expenditure: 120.5
  }
  @update_attrs %{
    description: "some updated description",
    days_worked: 43,
    expected_cashing: 456.7,
    received_cashing: 456.7,
    airtel_id: "some updated airtel_id",
    debt_balance: 456.7,
    expenditure: 456.7
  }
  @invalid_attrs %{description: nil, days_worked: nil, expected_cashing: nil, received_cashing: nil, airtel_id: nil, debt_balance: nil, expenditure: nil, report_id: nil}

  describe "index" do
    test "index displays the list page with all cashing reports", %{conn: conn} do
      conn = get(conn, ~p"/cashing_reports")
      response = html_response(conn, 200)
      
      assert response =~ "Listing Cashing reports"
    end
  end

  describe "new cashing_report" do
    test "renders the new cashing report form", %{conn: conn} do
      conn = get(conn, ~p"/cashing_reports/new")
      response = html_response(conn, 200)
      assert response =~ "New Cashing report"
      assert response =~ "form"
      # Verify form fields exist
      assert response =~ "Description"
      assert response =~ "Days worked"
    end
  end

  describe "create cashing_report" do
    test "successfully creates a cashing report and redirects to show page", %{conn: conn, report: report} do
      create_attrs = Map.put(@create_attrs, :report_id, report.id)
      conn = post(conn, ~p"/cashing_reports", cashing_report: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/cashing_reports/#{id}"

      conn = get(conn, ~p"/cashing_reports/#{id}")
      response = html_response(conn, 200)
      assert response =~ "Cashing report"
      assert response =~ "some description"
      assert response =~ "42" # days worked
      assert response =~ "120.5" # expected cashing formatted as string
    end

    test "renders errors when submitted data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/cashing_reports", cashing_report: @invalid_attrs)
      response = html_response(conn, 200)
      assert response =~ "New Cashing report"
      assert response =~ "can&#39;t be blank"
    end
  end

  describe "edit cashing_report" do
    setup [:create_cashing_report]

    test "renders form for editing an existing cashing report", %{conn: conn, cashing_report: cashing_report} do
      conn = get(conn, ~p"/cashing_reports/#{cashing_report}/edit")
      response = html_response(conn, 200)
      assert response =~ "Edit Cashing report"
      assert response =~ "form"
      # Verify that form contains the report's current values
      assert response =~ cashing_report.description
    end
  end

  describe "update cashing_report" do
    setup [:create_cashing_report]

    test "successfully updates a cashing report with valid data", %{conn: conn, cashing_report: cashing_report} do
      update_attrs = Map.put(@update_attrs, :report_id, cashing_report.report_id)
      conn = put(conn, ~p"/cashing_reports/#{cashing_report}", cashing_report: update_attrs)
      assert redirected_to(conn) == ~p"/cashing_reports/#{cashing_report}"

      conn = get(conn, ~p"/cashing_reports/#{cashing_report}")
      response = html_response(conn, 200)
      assert response =~ "some updated description"
      assert response =~ "43" # updated days_worked
      assert response =~ "456.7" # updated expected_cashing (displayed as string)
    end

    test "renders errors when update data is invalid", %{conn: conn, cashing_report: cashing_report} do
      conn = put(conn, ~p"/cashing_reports/#{cashing_report}", cashing_report: @invalid_attrs)
      response = html_response(conn, 200)
      assert response =~ "Edit Cashing report"
      assert response =~ "can&#39;t be blank"
    end
  end

  describe "delete cashing_report" do
    setup [:create_cashing_report]

    test "successfully deletes a cashing report and redirects to index", %{conn: conn, cashing_report: cashing_report} do
      # Store the ID before deletion for verification
      id = cashing_report.id
      
      # Delete the cashing report
      conn = delete(conn, ~p"/cashing_reports/#{cashing_report}")
      assert redirected_to(conn) == ~p"/cashing_reports"
      
      # Verify flash message if redirected to index
      next_conn = get(recycle(conn), ~p"/cashing_reports")
      assert html_response(next_conn, 200) =~ "Cashing report deleted successfully"
      
      # Verify the report no longer exists
      assert_error_sent 404, fn ->
        get(conn, ~p"/cashing_reports/#{id}")
      end
    end
  end

  defp create_cashing_report(_) do
    cashing_report = cashing_report_fixture()
    %{cashing_report: cashing_report}
  end
end
