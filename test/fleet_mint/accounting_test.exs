defmodule FleetMint.AccountingTest do
  use FleetMint.DataCase

  alias FleetMint.Accounting
  alias FleetMint.Accounting.LedgerEntry

  import FleetMint.AccountingFixtures

  describe "record_entry/1" do
    test "creates an entry with valid attrs" do
      assert {:ok, %LedgerEntry{} = entry} =
               Accounting.record_entry(%{
                 entry_type: "revenue",
                 source_type: "Booking",
                 source_id: 1,
                 amount: "150.00"
               })

      assert entry.entry_type == "revenue"
      assert Decimal.equal?(entry.amount, Decimal.new("150.00"))
      assert entry.occurred_at
    end

    test "requires entry_type, source_type, source_id, amount" do
      assert {:error, changeset} = Accounting.record_entry(%{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.entry_type
      assert "can't be blank" in errors.source_type
      assert "can't be blank" in errors.source_id
      assert "can't be blank" in errors.amount
    end

    test "rejects an entry_type outside the allowed set" do
      assert {:error, changeset} =
               Accounting.record_entry(%{
                 entry_type: "bogus",
                 source_type: "Booking",
                 source_id: 1,
                 amount: "10.00"
               })

      assert "is invalid" in errors_on(changeset).entry_type
    end

    test "rejects a payment_method outside the allowed set" do
      assert {:error, changeset} =
               Accounting.record_entry(%{
                 entry_type: "revenue",
                 source_type: "Booking",
                 source_id: 1,
                 amount: "10.00",
                 payment_method: "bitcoin"
               })

      assert "is invalid" in errors_on(changeset).payment_method
    end

    test "revenue/expense/refund amounts must be >= 0" do
      assert {:error, changeset} =
               Accounting.record_entry(%{
                 entry_type: "expense",
                 source_type: "FuelLog",
                 source_id: 1,
                 amount: "-10.00"
               })

      assert "must be greater than or equal to 0" in errors_on(changeset).amount
    end

    test "adjustment amounts may be negative but not zero" do
      assert {:ok, _} =
               Accounting.record_entry(%{
                 entry_type: "adjustment",
                 source_type: "CashingReport",
                 source_id: 1,
                 amount: "-25.00"
               })

      assert {:error, changeset} =
               Accounting.record_entry(%{
                 entry_type: "adjustment",
                 source_type: "CashingReport",
                 source_id: 1,
                 amount: "0"
               })

      assert "must be not equal to 0" in errors_on(changeset).amount
    end
  end

  describe "reverse_entry/2" do
    test "links the offsetting entry via reverses_entry_id" do
      original = ledger_entry_fixture(%{entry_type: "revenue", amount: "80.00"})
      assert {:ok, reversal} = Accounting.reverse_entry(original)

      assert reversal.entry_type == "refund"
      assert reversal.reverses_entry_id == original.id
      assert reversal.source_type == original.source_type
      assert reversal.source_id == original.source_id
      assert Decimal.equal?(reversal.amount, original.amount)
    end

    test "accepts an entry_type override" do
      original = ledger_entry_fixture(%{entry_type: "expense", amount: "40.00"})
      assert {:ok, reversal} = Accounting.reverse_entry(original, %{entry_type: "adjustment"})
      assert reversal.entry_type == "adjustment"
    end
  end

  describe "multi_insert_entry/3 and multi_reverse_entry/4" do
    test "multi_insert_entry commits an entry as part of a larger Multi" do
      {:ok, %{entry: entry}} =
        Ecto.Multi.new()
        |> Accounting.multi_insert_entry(:entry, %{
          entry_type: "revenue",
          source_type: "Booking",
          source_id: 42,
          amount: "60.00"
        })
        |> FleetMint.Repo.transaction()

      assert entry.source_id == 42
    end

    test "multi_reverse_entry no-ops when the lookup returns nil" do
      {:ok, result} =
        Ecto.Multi.new()
        |> Accounting.multi_reverse_entry(:refund, fn _changes -> nil end)
        |> FleetMint.Repo.transaction()

      assert result.refund == nil
    end

    test "multi_reverse_entry reverses the entry returned by the lookup fun" do
      original = ledger_entry_fixture(%{entry_type: "revenue", amount: "20.00"})

      {:ok, result} =
        Ecto.Multi.new()
        |> Accounting.multi_reverse_entry(:refund, fn _changes -> original end)
        |> FleetMint.Repo.transaction()

      assert result.refund.reverses_entry_id == original.id
    end
  end

  describe "entries_for_source/3" do
    test "filters by source and optional entry_type" do
      ledger_entry_fixture(%{source_type: "Booking", source_id: 7, entry_type: "revenue", amount: "10.00"})
      ledger_entry_fixture(%{source_type: "Booking", source_id: 7, entry_type: "refund", amount: "10.00"})
      ledger_entry_fixture(%{source_type: "Booking", source_id: 8, entry_type: "revenue", amount: "10.00"})

      assert length(Accounting.entries_for_source("Booking", 7)) == 2
      assert [%{entry_type: "revenue"}] = Accounting.entries_for_source("Booking", 7, "revenue")
    end
  end

  describe "aggregates" do
    test "total_for/2, totals_by_type/1, net_total/1 sum by entry_type" do
      ledger_entry_fixture(%{entry_type: "revenue", amount: "100.00", source_type: "Booking"})
      ledger_entry_fixture(%{entry_type: "revenue", amount: "50.00", source_type: "Invoice"})
      ledger_entry_fixture(%{entry_type: "expense", amount: "30.00", source_type: "FuelLog"})
      ledger_entry_fixture(%{entry_type: "refund", amount: "20.00", source_type: "Booking"})

      assert Decimal.equal?(Accounting.total_for("revenue"), Decimal.new("150.00"))
      assert Decimal.equal?(Accounting.total_for("revenue", source_type: "Booking"), Decimal.new("100.00"))

      totals = Accounting.totals_by_type()
      assert Decimal.equal?(totals["expense"], Decimal.new("30.00"))

      assert Decimal.equal?(Accounting.net_total(), Decimal.new("100.00"))
    end

    test "total_for/2 returns 0.00 when there are no matching entries" do
      assert Decimal.equal?(Accounting.total_for("expense", source_type: "Nonexistent"), Decimal.new("0.00"))
    end

    test "daily_summary/1 scopes totals to the given date" do
      today = Date.utc_today()
      {:ok, today_dt} = DateTime.new(today, ~T[12:00:00])
      yesterday = Date.add(today, -1)
      {:ok, yesterday_dt} = DateTime.new(yesterday, ~T[12:00:00])

      ledger_entry_fixture(%{entry_type: "revenue", amount: "100.00", occurred_at: today_dt})
      ledger_entry_fixture(%{entry_type: "revenue", amount: "999.00", occurred_at: yesterday_dt})

      summary = Accounting.daily_summary(today)
      assert Decimal.equal?(summary.revenue, Decimal.new("100.00"))
      assert summary.date == today
    end
  end
end
