defmodule FleetMint.Transport.FleetTest do
  use FleetMint.DataCase

  alias FleetMint.Accounting
  alias FleetMint.Transport.Fleet

  import FleetMint.FleetFixtures

  describe "create_fuel_log/1" do
    test "writes a matching expense entry for total_cost" do
      fuel_log = fuel_log_fixture(liters: "40.0", cost_per_liter: "25.00")

      assert [entry] = Accounting.entries_for_source("FuelLog", fuel_log.id)
      assert entry.entry_type == "expense"
      assert Decimal.equal?(entry.amount, Decimal.new("1000.00"))
    end
  end

  describe "update_fuel_log/2" do
    test "syncs the linked entry's amount" do
      fuel_log = fuel_log_fixture(liters: "40.0", cost_per_liter: "25.00")
      assert {:ok, updated} = Fleet.update_fuel_log(fuel_log, %{total_cost: "1200.00"})

      assert [entry] = Accounting.entries_for_source("FuelLog", updated.id)
      assert Decimal.equal?(entry.amount, Decimal.new("1200.00"))
    end
  end

  describe "create_maintenance/1" do
    test "writes a matching expense entry for cost" do
      maintenance = maintenance_fixture(cost: "450.00")

      assert [entry] = Accounting.entries_for_source("VehicleMaintenance", maintenance.id)
      assert entry.entry_type == "expense"
      assert Decimal.equal?(entry.amount, Decimal.new("450.00"))
    end

    test "writes no entry when cost is nil" do
      maintenance = maintenance_fixture()
      assert Accounting.entries_for_source("VehicleMaintenance", maintenance.id) == []
    end
  end

  describe "update_maintenance/2" do
    test "syncs the linked entry's amount" do
      maintenance = maintenance_fixture(cost: "100.00")
      assert {:ok, updated} = Fleet.update_maintenance(maintenance, %{cost: "250.00"})

      assert [entry] = Accounting.entries_for_source("VehicleMaintenance", updated.id)
      assert Decimal.equal?(entry.amount, Decimal.new("250.00"))
    end
  end
end
