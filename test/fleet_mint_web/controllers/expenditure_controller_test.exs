defmodule FleetMintWeb.ExpenditureControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FinanceFixtures
  import FleetMint.IdentityFixtures

  setup %{conn: conn} do
    {:ok, conn: log_in_user(conn, user_fixture())}
  end

  # We need a valid cashing_report_id for these tests
  @create_attrs %{
    description: "some description",
    amount: "120.5",
    date: DateTime.utc_now(),
    # Will be set in setup
    cashing_report_id: nil
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

      # Deletion is a soft delete (archived_at set) — the record survives
      # for audit purposes but drops out of the normal listing.
      refute expenditure.id in Enum.map(FleetMint.Finance.list_expenditures(), & &1.id)
      assert FleetMint.Repo.get!(FleetMint.Finance.Expenditure, expenditure.id).archived_at
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
