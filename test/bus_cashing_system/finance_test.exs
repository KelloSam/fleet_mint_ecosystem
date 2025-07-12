defmodule BusCashingSystem.FinanceTest do
  use BusCashingSystem.DataCase

  alias BusCashingSystem.Finance

  describe "cashing_reports" do
    alias BusCashingSystem.Finance.CashingReport

    import BusCashingSystem.FinanceFixtures

    @invalid_attrs %{description: nil, days_worked: nil, expected_cashing: nil, received_cashing: nil, airtel_id: nil, debt_balance: nil, expenditure: nil}

    test "list_cashing_reports/0 returns all cashing_reports" do
      cashing_report = cashing_report_fixture()
      assert Finance.list_cashing_reports() == [cashing_report]
    end

    test "get_cashing_report!/1 returns the cashing_report with given id" do
      cashing_report = cashing_report_fixture()
      assert Finance.get_cashing_report!(cashing_report.id) == cashing_report
    end

    test "create_cashing_report/1 with valid data creates a cashing_report" do
      # Create a report first to get a valid report_id
      report = BusCashingSystem.FinanceFixtures.report_fixture()
      valid_attrs = %{
        description: "some description", 
        days_worked: 42, 
        expected_cashing: "120.5", 
        received_cashing: "120.5", 
        airtel_id: "some airtel_id", 
        debt_balance: "120.5", 
        expenditure: "120.5",
        report_id: report.id
      }

      assert {:ok, %CashingReport{} = cashing_report} = Finance.create_cashing_report(valid_attrs)
      assert cashing_report.description == "some description"
      assert cashing_report.days_worked == 42
      assert cashing_report.expected_cashing == Decimal.new("120.5")
      assert cashing_report.received_cashing == Decimal.new("120.5")
      assert cashing_report.airtel_id == "some airtel_id"
      assert cashing_report.debt_balance == Decimal.new("120.5")
      assert cashing_report.expenditure == Decimal.new("120.5")
    end

    test "create_cashing_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Finance.create_cashing_report(@invalid_attrs)
    end

    test "update_cashing_report/2 with valid data updates the cashing_report" do
      cashing_report = cashing_report_fixture()
      update_attrs = %{description: "some updated description", days_worked: 43, expected_cashing: "456.7", received_cashing: "456.7", airtel_id: "some updated airtel_id", debt_balance: "456.7", expenditure: "456.7"}

      assert {:ok, %CashingReport{} = cashing_report} = Finance.update_cashing_report(cashing_report, update_attrs)
      assert cashing_report.description == "some updated description"
      assert cashing_report.days_worked == 43
      assert cashing_report.expected_cashing == Decimal.new("456.7")
      assert cashing_report.received_cashing == Decimal.new("456.7")
      assert cashing_report.airtel_id == "some updated airtel_id"
      assert cashing_report.debt_balance == Decimal.new("456.7")
      assert cashing_report.expenditure == Decimal.new("456.7")
    end

    test "update_cashing_report/2 with invalid data returns error changeset" do
      cashing_report = cashing_report_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.update_cashing_report(cashing_report, @invalid_attrs)
      assert cashing_report == Finance.get_cashing_report!(cashing_report.id)
    end

    test "delete_cashing_report/1 deletes the cashing_report" do
      cashing_report = cashing_report_fixture()
      assert {:ok, %CashingReport{}} = Finance.delete_cashing_report(cashing_report)
      assert_raise Ecto.NoResultsError, fn -> Finance.get_cashing_report!(cashing_report.id) end
    end

    test "change_cashing_report/1 returns a cashing_report changeset" do
      cashing_report = cashing_report_fixture()
      assert %Ecto.Changeset{} = Finance.change_cashing_report(cashing_report)
    end
  end

  describe "expenditures" do
    alias BusCashingSystem.Finance.Expenditure

    import BusCashingSystem.FinanceFixtures

    @invalid_attrs %{description: nil, amount: nil}

    test "list_expenditures/0 returns all expenditures" do
      expenditure = expenditure_fixture()
      assert Finance.list_expenditures() == [expenditure]
    end

    test "get_expenditure!/1 returns the expenditure with given id" do
      expenditure = expenditure_fixture()
      assert Finance.get_expenditure!(expenditure.id) == expenditure
    end

    test "create_expenditure/1 with valid data creates a expenditure" do
      # Create a cashing report first to get a valid cashing_report_id
      {:ok, cashing_report} = Finance.create_cashing_report(%{
        description: "some description", 
        days_worked: 42, 
        expected_cashing: "120.5", 
        received_cashing: "120.5", 
        airtel_id: "some airtel_id", 
        debt_balance: "120.5", 
        expenditure: "120.5",
        report_id: BusCashingSystem.FinanceFixtures.report_fixture().id
      })
      
      valid_attrs = %{
        description: "some description", 
        amount: "120.5", 
        date: DateTime.utc_now(),
        cashing_report_id: cashing_report.id
      }

      assert {:ok, %Expenditure{} = expenditure} = Finance.create_expenditure(valid_attrs)
      assert expenditure.description == "some description"
      assert expenditure.amount == Decimal.new("120.5")
    end

    test "create_expenditure/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Finance.create_expenditure(@invalid_attrs)
    end

    test "update_expenditure/2 with valid data updates the expenditure" do
      expenditure = expenditure_fixture()
      update_attrs = %{description: "some updated description", amount: "456.7"}

      assert {:ok, %Expenditure{} = expenditure} = Finance.update_expenditure(expenditure, update_attrs)
      assert expenditure.description == "some updated description"
      assert expenditure.amount == Decimal.new("456.7")
    end

    test "update_expenditure/2 with invalid data returns error changeset" do
      expenditure = expenditure_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.update_expenditure(expenditure, @invalid_attrs)
      assert expenditure == Finance.get_expenditure!(expenditure.id)
    end

    test "delete_expenditure/1 deletes the expenditure" do
      expenditure = expenditure_fixture()
      assert {:ok, %Expenditure{}} = Finance.delete_expenditure(expenditure)
      assert_raise Ecto.NoResultsError, fn -> Finance.get_expenditure!(expenditure.id) end
    end

    test "change_expenditure/1 returns a expenditure changeset" do
      expenditure = expenditure_fixture()
      assert %Ecto.Changeset{} = Finance.change_expenditure(expenditure)
    end
  end
end
