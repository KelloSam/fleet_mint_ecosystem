defmodule FleetMint.Accounting do
  @moduledoc """
  The single-entry cash ledger that all money-moving flows across the app
  (fares, freight payments, cashier shifts, operating costs) write through.

  Other contexts do not call `record_entry/1` directly for their own writes —
  they use `multi_insert_entry/3` / `multi_reverse_entry/4` to add a ledger
  step to their own `Ecto.Multi`, so the domain record and its ledger entry
  commit atomically in one transaction.
  """
  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Accounting.LedgerEntry

  # ── Writing (standalone) ──────────────────────────────────────────────────

  def record_entry(attrs) do
    %LedgerEntry{} |> LedgerEntry.changeset(attrs) |> Repo.insert()
  end

  def change_entry(entry \\ %LedgerEntry{}, attrs \\ %{}) do
    LedgerEntry.changeset(entry, attrs)
  end

  @doc """
  Builds the offsetting entry for `original`, linked via `reverses_entry_id`.
  Defaults to `entry_type: "refund"` — pass `%{entry_type: "adjustment"}` in
  `attrs` for non-refund reversals.
  """
  def reverse_entry(%LedgerEntry{} = original, attrs \\ %{}) do
    attrs
    |> Map.new()
    |> Map.put_new(:entry_type, "refund")
    |> Map.merge(%{
      source_type: original.source_type,
      source_id: original.source_id,
      amount: original.amount,
      payment_method: original.payment_method,
      reverses_entry_id: original.id
    })
    |> record_entry()
  end

  # ── Ecto.Multi step builders (used from other contexts) ───────────────────

  def multi_insert_entry(multi, name, attrs) when is_function(attrs, 1) do
    Ecto.Multi.insert(multi, name, fn changes ->
      LedgerEntry.changeset(%LedgerEntry{}, attrs.(changes))
    end)
  end

  def multi_insert_entry(multi, name, attrs) do
    Ecto.Multi.insert(multi, name, LedgerEntry.changeset(%LedgerEntry{}, attrs))
  end

  @doc """
  Adds a reversal step to `multi`. `original_fun` receives the Multi's changes
  so far and must return the `%LedgerEntry{}` to reverse, or `nil` to no-op
  (safe for records that predate ledger integration and have no linked entry).
  """
  def multi_reverse_entry(multi, name, original_fun, attrs \\ %{}) when is_function(original_fun, 1) do
    Ecto.Multi.run(multi, name, fn _repo, changes ->
      case original_fun.(changes) do
        nil -> {:ok, nil}
        %LedgerEntry{} = original -> reverse_entry(original, attrs)
      end
    end)
  end

  # ── Lookups ─────────────────────────────────────────────────────────────

  def get_entry!(id), do: Repo.get!(LedgerEntry, id)

  def entries_for_source(source_type, source_id, entry_type \\ nil) do
    LedgerEntry
    |> where([e], e.source_type == ^source_type and e.source_id == ^source_id)
    |> maybe_filter_type(entry_type)
    |> order_by([e], asc: e.inserted_at)
    |> Repo.all()
  end

  def list_entries(opts \\ []) do
    LedgerEntry
    |> maybe_filter_type(opts[:entry_type])
    |> maybe_filter_source(opts[:source_type])
    |> maybe_filter_range(opts[:from], opts[:to])
    |> order_by([e], desc: e.occurred_at)
    |> Repo.all()
  end

  # ── Aggregates ────────────────────────────────────────────────────────────

  def total_for(entry_type, opts \\ []) do
    LedgerEntry
    |> where([e], e.entry_type == ^entry_type)
    |> maybe_filter_range(opts[:from], opts[:to])
    |> maybe_filter_source(opts[:source_type])
    |> select([e], sum(e.amount))
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0.00")
      total -> total
    end
  end

  def totals_by_type(opts \\ []) do
    LedgerEntry
    |> maybe_filter_range(opts[:from], opts[:to])
    |> group_by([e], e.entry_type)
    |> select([e], {e.entry_type, sum(e.amount)})
    |> Repo.all()
    |> Map.new()
  end

  def net_total(opts \\ []) do
    totals = totals_by_type(opts)
    revenue = Map.get(totals, "revenue", Decimal.new(0))
    refund = Map.get(totals, "refund", Decimal.new(0))
    expense = Map.get(totals, "expense", Decimal.new(0))
    adjustment = Map.get(totals, "adjustment", Decimal.new(0))

    revenue
    |> Decimal.sub(refund)
    |> Decimal.sub(expense)
    |> Decimal.add(adjustment)
  end

  def daily_summary(%Date{} = date) do
    {:ok, from} = DateTime.new(date, ~T[00:00:00])
    {:ok, to} = DateTime.new(date, ~T[23:59:59])
    totals = totals_by_type(from: from, to: to)

    %{
      date: date,
      revenue: Map.get(totals, "revenue", Decimal.new(0)),
      expense: Map.get(totals, "expense", Decimal.new(0)),
      refund: Map.get(totals, "refund", Decimal.new(0)),
      adjustment: Map.get(totals, "adjustment", Decimal.new(0)),
      net: net_total(from: from, to: to)
    }
  end

  # ── Private ───────────────────────────────────────────────────────────────

  defp maybe_filter_type(query, nil), do: query
  defp maybe_filter_type(query, type), do: where(query, [e], e.entry_type == ^type)

  defp maybe_filter_source(query, nil), do: query
  defp maybe_filter_source(query, source_type), do: where(query, [e], e.source_type == ^source_type)

  defp maybe_filter_range(query, nil, nil), do: query
  defp maybe_filter_range(query, from, to), do: where(query, [e], e.occurred_at >= ^from and e.occurred_at <= ^to)
end
