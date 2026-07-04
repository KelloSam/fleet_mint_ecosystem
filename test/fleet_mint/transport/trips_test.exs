defmodule FleetMint.Transport.TripsTest do
  use FleetMint.DataCase

  alias FleetMint.Accounting
  alias FleetMint.Transport.Trips

  import FleetMint.FleetFixtures

  describe "create_minibus_trip/1" do
    test "writes separate revenue and expense entries for fare_collected and fuel_cost" do
      trip = minibus_trip_fixture(fare_collected: "300.00", fuel_cost: "50.00")

      revenue = Accounting.entries_for_source("MinibusTrip", trip.id, "revenue")
      expense = Accounting.entries_for_source("MinibusTrip", trip.id, "expense")

      assert [%{entry_type: "revenue"} = r] = revenue
      assert [%{entry_type: "expense"} = e] = expense
      assert Decimal.equal?(r.amount, Decimal.new("300.00"))
      assert Decimal.equal?(e.amount, Decimal.new("50.00"))
    end

    test "writes no entries when fare_collected and fuel_cost are nil" do
      trip = minibus_trip_fixture()
      assert Accounting.entries_for_source("MinibusTrip", trip.id) == []
    end
  end

  describe "update_minibus_trip/2" do
    test "syncs both entries independently as values change" do
      trip = minibus_trip_fixture(fare_collected: "100.00", fuel_cost: "20.00")
      assert {:ok, updated} = Trips.update_minibus_trip(trip, %{fare_collected: "150.00", fuel_cost: "0"})

      assert [%{amount: amount}] = Accounting.entries_for_source("MinibusTrip", updated.id, "revenue")
      assert Decimal.equal?(amount, Decimal.new("150.00"))
      assert Accounting.entries_for_source("MinibusTrip", updated.id, "expense") == []
    end
  end
end
