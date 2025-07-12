defmodule BusCashingSystemWeb.ExpenditureControllerTest do
  use BusCashingSystemWeb.ConnCase

  import BusCashingSystem.FinanceFixtures

  # We need a valid cashing_report_id for these tests
  @create_attrs %{
    description: "some description", 
    amount: "120.5",
    date: DateTime.utc_now(),
    cashing_report_id: nil  # Will be set in setup
  }
  @update_attrs %{
    description: "some updated description", 
    amount: "456.7",
    date: DateTime.utc_now()
  }
  @invalid_attrs %{description: nil, amount: nil}

  describe "index" do
    test "lists all expenditures", %{conn: conn} do
      conn = get(conn, ~p"/expenditures")
      assert html_response(conn, 200) =~ "Listing Expenditures"
    end
  end

  describe "new expenditure" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/expenditures/new")
      assert html_response(conn, 200) =~ "New Expenditure"
    end
  end

  describe "create expenditure" do
    test "redirects to show when data is valid", %{conn: conn} do
      # Create a cashing report for this test
      cashing_report = cashing_report_fixture()
      create_attrs = Map.put(@create_attrs, :cashing_report_id, cashing_report.id)
      
      conn = post(conn, ~p"/expenditures", expenditure: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/expenditures/#{id}"

      conn = get(conn, ~p"/expenditures/#{id}")
      assert html_response(conn, 200) =~ "Expenditure #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/expenditures", expenditure: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Expenditure"
    end
  end

  describe "edit expenditure" do
    setup [:create_expenditure]

    test "renders form for editing chosen expenditure", %{conn: conn, expenditure: expenditure} do
      conn = get(conn, ~p"/expenditures/#{expenditure}/edit")
      assert html_response(conn, 200) =~ "Edit Expenditure"
    end
  end

  describe "update expenditure" do
    setup [:create_expenditure]

    test "redirects when data is valid", %{conn: conn, expenditure: expenditure} do
      conn = put(conn, ~p"/expenditures/#{expenditure}", expenditure: @update_attrs)
      assert redirected_to(conn) == ~p"/expenditures/#{expenditure}"

      conn = get(conn, ~p"/expenditures/#{expenditure}")
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, expenditure: expenditure} do
      conn = put(conn, ~p"/expenditures/#{expenditure}", expenditure: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Expenditure"
    end
  end

  describe "delete expenditure" do
    setup [:create_expenditure]

    test "deletes chosen expenditure", %{conn: conn, expenditure: expenditure} do
      conn = delete(conn, ~p"/expenditures/#{expenditure}")
      assert redirected_to(conn) == ~p"/expenditures"

      assert_error_sent 404, fn ->
        get(conn, ~p"/expenditures/#{expenditure}")
      end
    end
  end

  defp create_expenditure(_) do
    # Create a cashing report first
    cashing_report = cashing_report_fixture()
    
    # Create expenditure with the cashing_report_id
    expenditure = expenditure_fixture(%{cashing_report_id: cashing_report.id})
    
    %{expenditure: expenditure, cashing_report: cashing_report}
  end
end
