defmodule FleetMint.ReportsTest do
  use FleetMint.DataCase

  alias FleetMint.Finance

  describe "weekly_reports" do
    alias FleetMint.Finance.Report

    import FleetMint.ReportsFixtures

    @invalid_attrs %{start_date: nil, end_date: nil}

    test "list_weekly_reports/0 returns all weekly_reports" do
      report = report_fixture()
      assert Finance.list_weekly_reports() == [report]
    end

    test "get_report!/1 returns the report with given id" do
      report = report_fixture()
      assert Finance.get_report!(report.id) == report
    end

    test "create_report/1 with valid data creates a report" do
      valid_attrs = %{start_date: ~D[2025-03-03], end_date: ~D[2025-03-03]}

      assert {:ok, %Report{} = report} = Finance.create_report(valid_attrs)
      assert report.start_date == ~D[2025-03-03]
      assert report.end_date == ~D[2025-03-03]
    end

    test "create_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Finance.create_report(@invalid_attrs)
    end

    test "update_report/2 with valid data updates the report" do
      report = report_fixture()
      update_attrs = %{start_date: ~D[2025-03-04], end_date: ~D[2025-03-04]}

      assert {:ok, %Report{} = report} = Finance.update_report(report, update_attrs)
      assert report.start_date == ~D[2025-03-04]
      assert report.end_date == ~D[2025-03-04]
    end

    test "update_report/2 with invalid data returns error changeset" do
      report = report_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.update_report(report, @invalid_attrs)
      assert report == Finance.get_report!(report.id)
    end

    test "delete_report/1 deletes the report" do
      report = report_fixture()
      assert {:ok, %Report{}} = Finance.delete_report(report)
      assert_raise Ecto.NoResultsError, fn -> Finance.get_report!(report.id) end
    end

    test "change_report/1 returns a report changeset" do
      report = report_fixture()
      assert %Ecto.Changeset{} = Finance.change_report(report)
    end
  end
end
