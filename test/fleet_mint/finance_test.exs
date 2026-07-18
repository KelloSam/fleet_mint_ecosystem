defmodule FleetMint.FinanceTest do
  use FleetMint.DataCase

  alias FleetMint.Finance
  alias FleetMint.Accounting
  alias FleetMint.Finance.CashingReportTrip
  alias FleetMint.Repo
  alias FleetMint.Transport.Trips

  describe "attempt_trip_match/1 (Phase 2b cashing_report <-> Trip reconciliation)" do
    import FleetMint.FinanceFixtures
    import FleetMint.FleetFixtures
    import FleetMint.TicketingFixtures

    test "unmappable: no bus on the report" do
      cashing_report = cashing_report_fixture()
      assert {:unmappable, "No bus recorded on this report."} = Finance.attempt_trip_match(cashing_report)
    end

    test "unmappable: bus has no vehicle assignment" do
      operator = operator_fixture()
      bus = bus_fixture(organisation_id: operator.organisation_id)
      cashing_report = cashing_report_fixture(%{bus_id: bus.id})

      assert {:unmappable, "Bus has no vehicle assignment recorded."} = Finance.attempt_trip_match(cashing_report)
    end

    test "unmappable: vehicle has never been assigned to any schedule" do
      operator = operator_fixture()
      vehicle = vehicle_fixture()
      bus = bus_fixture(organisation_id: operator.organisation_id, vehicle_id: vehicle.id)
      cashing_report = cashing_report_fixture(%{bus_id: bus.id})

      assert {:unmappable, "No schedule has ever been assigned this vehicle."} =
               Finance.attempt_trip_match(cashing_report)
    end

    test "unmappable: matching schedule exists but no Trip is recorded for that date" do
      operator = operator_fixture()
      vehicle = vehicle_fixture()
      bus = bus_fixture(organisation_id: operator.organisation_id, vehicle_id: vehicle.id)
      schedule_fixture(operator_id: operator.id, vehicle_id: vehicle.id)

      cashing_report = cashing_report_fixture(%{bus_id: bus.id, report_date: ~D[2026-08-01]})

      assert {:unmappable, notes} = Finance.attempt_trip_match(cashing_report)
      assert notes =~ "no trip is recorded"
    end

    test "unmappable: vehicle only used on a schedule belonging to a different organisation" do
      operator_a = operator_fixture()
      operator_b = operator_fixture()
      vehicle = vehicle_fixture()
      bus = bus_fixture(organisation_id: operator_a.organisation_id, vehicle_id: vehicle.id)
      schedule_fixture(operator_id: operator_b.id, vehicle_id: vehicle.id)

      cashing_report = cashing_report_fixture(%{bus_id: bus.id})

      assert {:unmappable, notes} = Finance.attempt_trip_match(cashing_report)
      assert notes =~ "different organisation"
    end

    test "ambiguous: vehicle is assigned to more than one schedule in the same organisation" do
      operator = operator_fixture()
      vehicle = vehicle_fixture()
      bus = bus_fixture(organisation_id: operator.organisation_id, vehicle_id: vehicle.id)
      schedule_fixture(operator_id: operator.id, vehicle_id: vehicle.id)
      schedule_fixture(operator_id: operator.id, vehicle_id: vehicle.id)

      cashing_report = cashing_report_fixture(%{bus_id: bus.id})

      assert {:ambiguous, notes} = Finance.attempt_trip_match(cashing_report)
      assert notes =~ "more than one schedule"
    end

    test "automatically_matched: exactly one same-organisation schedule, with a Trip on that date" do
      operator = operator_fixture()
      vehicle = vehicle_fixture()
      bus = bus_fixture(organisation_id: operator.organisation_id, vehicle_id: vehicle.id)
      schedule = schedule_fixture(operator_id: operator.id, vehicle_id: vehicle.id)
      {:ok, trip} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])

      cashing_report = cashing_report_fixture(%{bus_id: bus.id, report_date: ~D[2026-08-01]})

      assert {:automatically_matched, matched_trip, organisation_id} = Finance.attempt_trip_match(cashing_report)
      assert matched_trip.id == trip.id
      assert organisation_id == operator.organisation_id
    end

    test "create_cashing_report/1 automatically allocates cash to the matched Trip and records the reconciliation state" do
      operator = operator_fixture()
      vehicle = vehicle_fixture()
      bus = bus_fixture(organisation_id: operator.organisation_id, vehicle_id: vehicle.id)
      schedule = schedule_fixture(operator_id: operator.id, vehicle_id: vehicle.id)
      {:ok, trip} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])

      cashing_report = cashing_report_fixture(%{bus_id: bus.id, report_date: ~D[2026-08-01], received_cashing: "300.00"})

      assert cashing_report.trip_mapping_status == "automatically_matched"

      assert [allocation] = Repo.all(CashingReportTrip)
      assert allocation.cashing_report_id == cashing_report.id
      assert allocation.trip_id == trip.id
      assert allocation.match_method == "automatic"
      assert Decimal.equal?(allocation.allocated_amount, Decimal.new("300.00"))
    end

    test "create_cashing_report/1 leaves an unmatchable report unmappable without inventing a Trip" do
      cashing_report = cashing_report_fixture()

      assert cashing_report.trip_mapping_status == "unmappable"
      assert Repo.all(CashingReportTrip) == []
    end
  end

  describe "match_cashing_report_to_trip/4 (manual reconciliation)" do
    import FleetMint.FinanceFixtures
    import FleetMint.FleetFixtures
    import FleetMint.TicketingFixtures
    import FleetMint.IdentityFixtures

    test "manually matches an ambiguous report to a chosen Trip" do
      operator = operator_fixture()
      vehicle = vehicle_fixture()
      bus = bus_fixture(organisation_id: operator.organisation_id, vehicle_id: vehicle.id)
      schedule = schedule_fixture(operator_id: operator.id, vehicle_id: vehicle.id)
      {:ok, trip} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])
      staff = user_fixture()

      cashing_report = cashing_report_fixture(%{bus_id: bus.id})
      assert cashing_report.trip_mapping_status == "unmappable"

      assert {:ok, matched} = Finance.match_cashing_report_to_trip(cashing_report, trip, staff)
      assert matched.trip_mapping_status == "manually_matched"

      assert [allocation] = Repo.all(CashingReportTrip)
      assert allocation.trip_id == trip.id
      assert allocation.match_method == "manual"
      assert allocation.matched_by_id == staff.id
    end

    test "rejects a manual match across organisations without touching either record" do
      operator_a = operator_fixture()
      operator_b = operator_fixture()
      vehicle_a = vehicle_fixture()
      bus_a = bus_fixture(organisation_id: operator_a.organisation_id, vehicle_id: vehicle_a.id)
      schedule_b = schedule_fixture(operator_id: operator_b.id)
      {:ok, trip_b} = Trips.get_or_create_trip(schedule_b.id, ~D[2026-08-01])
      staff = user_fixture()

      cashing_report = cashing_report_fixture(%{bus_id: bus_a.id})

      assert {:error, :organisation_mismatch} = Finance.match_cashing_report_to_trip(cashing_report, trip_b, staff)
      assert Repo.all(CashingReportTrip) == []

      reloaded = Finance.get_cashing_report!(cashing_report.id)
      assert reloaded.trip_mapping_status == cashing_report.trip_mapping_status
    end

    test "rejects a manual match when the report has no bus at all" do
      staff = user_fixture()
      operator = operator_fixture()
      schedule = schedule_fixture(operator_id: operator.id)
      {:ok, trip} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])

      cashing_report = cashing_report_fixture()

      assert {:error, :no_bus_on_report} = Finance.match_cashing_report_to_trip(cashing_report, trip, staff)
    end
  end

  describe "cashing_report_trips tenant isolation at the database level" do
    import FleetMint.FinanceFixtures
    import FleetMint.FleetFixtures
    import FleetMint.TicketingFixtures

    test "an allocation cannot be inserted with a trip_id/organisation_id mismatch" do
      operator_a = operator_fixture()
      operator_b = operator_fixture()
      schedule = schedule_fixture(operator_id: operator_a.id)
      {:ok, trip} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])

      # Bus-less on purpose: attempt_trip_match/1 leaves this unmappable
      # (no auto-allocation), so the row this test inserts is the only
      # one that will exist for this cashing_report/trip pair — the point
      # is proving the database itself rejects the mismatch, independent
      # of whatever reconciliation state the report happens to be in.
      cashing_report = cashing_report_fixture()

      changeset =
        CashingReportTrip.changeset(%CashingReportTrip{}, %{
          cashing_report_id: cashing_report.id,
          trip_id: trip.id,
          # Wrong organisation on purpose — trip_id alone points at a real
          # Trip, but the pair must not be accepted.
          organisation_id: operator_b.organisation_id,
          allocated_amount: "50.00",
          match_method: "manual",
          matched_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })

      assert_raise Ecto.ConstraintError, fn -> Repo.insert(changeset) end
    end
  end

  describe "list_cashing_reports/1 tenant scoping" do
    import FleetMint.FinanceFixtures
    import FleetMint.FleetFixtures

    test "organisation_id filters to cashing reports on that organisation's buses only" do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(organisation_id: org_a.organisation_id)
      bus_b = bus_fixture(organisation_id: org_b.organisation_id)

      report_a = cashing_report_fixture(%{bus_id: bus_a.id})
      cashing_report_fixture(%{bus_id: bus_b.id})

      result = Finance.list_cashing_reports(organisation_id: org_a.organisation_id)

      assert Enum.map(result, & &1.id) == [report_a.id]
    end
  end

  describe "list_expenditures/1 tenant scoping" do
    import FleetMint.FinanceFixtures
    import FleetMint.FleetFixtures

    test "organisation_id filters through cashing_report -> bus to that organisation only" do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(organisation_id: org_a.organisation_id)
      bus_b = bus_fixture(organisation_id: org_b.organisation_id)

      report_a = cashing_report_fixture(%{bus_id: bus_a.id})
      report_b = cashing_report_fixture(%{bus_id: bus_b.id})

      expenditure_a = expenditure_fixture(%{cashing_report_id: report_a.id})
      expenditure_fixture(%{cashing_report_id: report_b.id})

      result = Finance.list_expenditures(organisation_id: org_a.organisation_id)

      assert Enum.map(result, & &1.id) == [expenditure_a.id]
    end
  end

  describe "cashing_reports" do
    alias FleetMint.Finance.CashingReport

    import FleetMint.FinanceFixtures

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
      report = FleetMint.FinanceFixtures.report_fixture()
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

    test "create_cashing_report/1 writes a matching revenue ledger entry" do
      report = FleetMint.FinanceFixtures.report_fixture()

      {:ok, cashing_report} =
        Finance.create_cashing_report(%{
          description: "some description",
          days_worked: 42,
          expected_cashing: "120.5",
          received_cashing: "200.00",
          airtel_id: "some airtel_id",
          debt_balance: "0",
          expenditure: "0",
          report_id: report.id,
          report_date: report.start_date
        })

      assert [entry] = Accounting.entries_for_source("CashingReport", cashing_report.id)
      assert entry.entry_type == "revenue"
      assert Decimal.equal?(entry.amount, Decimal.new("200.00"))
    end

    test "update_cashing_report/2 syncs the linked ledger entry's amount" do
      cashing_report = cashing_report_fixture(%{received_cashing: "100.00"})
      assert {:ok, updated} = Finance.update_cashing_report(cashing_report, %{received_cashing: "300.00"})

      assert [entry] = Accounting.entries_for_source("CashingReport", updated.id)
      assert Decimal.equal?(entry.amount, Decimal.new("300.00"))
    end
  end

  describe "expenditures" do
    alias FleetMint.Finance.Expenditure

    import FleetMint.FinanceFixtures

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
        report_id: FleetMint.FinanceFixtures.report_fixture().id
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

    test "create_expenditure/1 writes a matching expense ledger entry" do
      cashing_report = cashing_report_fixture()

      {:ok, expenditure} =
        Finance.create_expenditure(%{
          description: "fuel",
          amount: "75.50",
          date: DateTime.utc_now(),
          cashing_report_id: cashing_report.id
        })

      assert [entry] = Accounting.entries_for_source("Expenditure", expenditure.id)
      assert entry.entry_type == "expense"
      assert Decimal.equal?(entry.amount, Decimal.new("75.50"))
    end

    test "update_expenditure/2 syncs the linked ledger entry's amount" do
      expenditure = expenditure_fixture(%{amount: "10.00"})
      assert {:ok, updated} = Finance.update_expenditure(expenditure, %{amount: "45.00"})

      assert [entry] = Accounting.entries_for_source("Expenditure", updated.id)
      assert Decimal.equal?(entry.amount, Decimal.new("45.00"))
    end
  end
end
