defmodule FleetMint.CargoTest do
  use FleetMint.DataCase

  alias FleetMint.Accounting
  alias FleetMint.Cargo

  import FleetMint.CargoFixtures

  alias FleetMint.FleetFixtures

  describe "tenant scoping" do
    test "list_clients/1 organisation_id filters to that organisation's clients only" do
      org_a = FleetFixtures.operator_fixture()
      org_b = FleetFixtures.operator_fixture()

      client_a = client_fixture(organisation_id: org_a.organisation_id)
      client_fixture(organisation_id: org_b.organisation_id)

      result = Cargo.list_clients(organisation_id: org_a.organisation_id)

      assert Enum.map(result, & &1.id) == [client_a.id]
    end

    test "list_orders/1 organisation_id filters through the order's client" do
      org_a = FleetFixtures.operator_fixture()
      org_b = FleetFixtures.operator_fixture()

      order_a = order_fixture(client: client_fixture(organisation_id: org_a.organisation_id))
      order_fixture(client: client_fixture(organisation_id: org_b.organisation_id))

      result = Cargo.list_orders(organisation_id: org_a.organisation_id)

      assert Enum.map(result, & &1.id) == [order_a.id]
    end

    test "list_trips/1 organisation_id filters through the trip's vehicle" do
      org_a = FleetFixtures.operator_fixture()
      org_b = FleetFixtures.operator_fixture()

      trip_a = trip_fixture(vehicle: vehicle_fixture(%{"organisation_id" => org_a.organisation_id}))
      trip_fixture(vehicle: vehicle_fixture(%{"organisation_id" => org_b.organisation_id}))

      result = Cargo.list_trips(organisation_id: org_a.organisation_id)

      assert Enum.map(result, & &1.id) == [trip_a.id]
    end

    test "list_invoices/1 organisation_id filters through the invoice's client" do
      org_a = FleetFixtures.operator_fixture()
      org_b = FleetFixtures.operator_fixture()

      invoice_a = invoice_fixture(client: client_fixture(organisation_id: org_a.organisation_id))
      invoice_fixture(client: client_fixture(organisation_id: org_b.organisation_id))

      result = Cargo.list_invoices(organisation_id: org_a.organisation_id)

      assert Enum.map(result, & &1.id) == [invoice_a.id]
    end
  end

  describe "invoices" do
    test "create_invoice/2 writes no ledger entry (no cash has moved)" do
      invoice = invoice_fixture(base_amount: "500.00")
      assert Accounting.entries_for_source("Invoice", invoice.id) == []
    end

    test "mark_invoice_paid/2 writes a matching revenue entry for total_amount" do
      invoice = invoice_fixture(base_amount: "1000.00")
      assert {:ok, paid} = Cargo.mark_invoice_paid(invoice, "REF-1")
      assert paid.status == "paid"

      assert [entry] = Accounting.entries_for_source("Invoice", paid.id)
      assert entry.entry_type == "revenue"
      assert Decimal.equal?(entry.amount, paid.total_amount)
      assert entry.reference_number == "REF-1"
    end

    test "mark_invoice_paid/2 does not double-record when called again" do
      invoice = invoice_fixture(base_amount: "1000.00")
      assert {:ok, paid} = Cargo.mark_invoice_paid(invoice, "REF-1")
      assert {:ok, paid_again} = Cargo.mark_invoice_paid(paid, "REF-2")

      assert length(Accounting.entries_for_source("Invoice", paid_again.id)) == 1
    end

    test "update_invoice/2 with a non-paid status transition writes no entry" do
      invoice = invoice_fixture()
      assert {:ok, issued} = Cargo.update_invoice(invoice, %{status: "issued"})
      assert Accounting.entries_for_source("Invoice", issued.id) == []
    end
  end

  describe "trips" do
    test "create_trip/2 with zero expenses writes no ledger entry" do
      trip = trip_fixture()
      assert Accounting.entries_for_source("FreightTrip", trip.id) == []
    end

    test "create_trip/2 with toll/other expenses writes a combined expense entry" do
      trip = trip_fixture(toll_fees: "20.00", other_expenses: "5.00")

      assert [entry] = Accounting.entries_for_source("FreightTrip", trip.id)
      assert entry.entry_type == "expense"
      assert Decimal.equal?(entry.amount, Decimal.new("25.00"))
    end

    test "update_trip/2 syncs the combined expense entry as costs change" do
      trip = trip_fixture(toll_fees: "20.00")
      assert {:ok, updated} = Cargo.update_trip(trip, %{other_expenses: "30.00"})

      assert [entry] = Accounting.entries_for_source("FreightTrip", updated.id)
      assert Decimal.equal?(entry.amount, Decimal.new("50.00"))
    end

    test "update_trip/2 removes the entry once expenses drop back to zero" do
      trip = trip_fixture(toll_fees: "20.00")
      assert {:ok, updated} = Cargo.update_trip(trip, %{toll_fees: "0"})

      assert Accounting.entries_for_source("FreightTrip", updated.id) == []
    end
  end
end
