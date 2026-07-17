defmodule FleetMint.Finance.Reconciliation do
  @moduledoc """
  Cross-checks money recorded across the three revenue streams — minibus
  cashing, intercity bookings, and freight invoices. `FleetMint.Accounting`
  is now the shared ledger every one of these streams writes through, so
  these three queries agree with it by construction; this module still reads
  directly from the domain tables (not the ledger) since that's what each
  comparison is actually about — e.g. checking the conductor's self-reported
  `received_cashing` against the trip log, not against the ledger entry that
  was derived from `received_cashing` in the first place.
  """

  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Transport.Trips.MinibusTrip
  alias FleetMint.Finance.CashingReport
  alias FleetMint.Transport.Ticketing.Booking
  alias FleetMint.Cargo.Invoice

  @doc """
  For each cashing report on `date`, compares the conductor's self-reported
  `received_cashing` against the actual sum of `fare_collected` logged on
  that bus's minibus trips for the same date. Flags any mismatch.
  """
  def minibus_variance_for_date(%Date{} = date) do
    trip_totals =
      from(t in MinibusTrip,
        where: t.date == ^date,
        group_by: t.bus_id,
        select: {t.bus_id, sum(t.fare_collected)}
      )
      |> Repo.all()
      |> Map.new(fn {bus_id, total} -> {bus_id, total || Decimal.new(0)} end)

    from(cr in CashingReport,
      where: cr.report_date == ^date,
      preload: [:bus, :conductor]
    )
    |> Repo.all()
    |> Enum.map(fn cr ->
      trip_log_total = Map.get(trip_totals, cr.bus_id, Decimal.new(0))
      variance = Decimal.sub(trip_log_total, cr.received_cashing)

      %{
        bus: cr.bus,
        conductor: cr.conductor,
        trip_log_total: trip_log_total,
        reported_expected: cr.expected_cashing,
        reported_received: cr.received_cashing,
        variance: variance,
        reconciled?: Decimal.equal?(variance, Decimal.new(0))
      }
    end)
  end

  @doc """
  Sums intercity `fare_paid` for `date`, grouped by cashier and payment
  method. Excludes cancelled bookings, matching the convention already used
  by `Transport.Ticketing.revenue_today/0`.
  """
  def intercity_collections_for_date(%Date{} = date) do
    from(b in Booking,
      where: b.travel_date == ^date and b.status != "cancelled",
      join: u in assoc(b, :booked_by),
      group_by: [b.booked_by_id, u.full_name, b.payment_method],
      select: %{
        cashier_id: b.booked_by_id,
        cashier_name: u.full_name,
        payment_method: b.payment_method,
        total: sum(b.fare_paid),
        booking_count: count(b.id)
      }
    )
    |> Repo.all()
    |> Enum.group_by(& &1.cashier_name)
  end

  @doc """
  Counts and sums freight invoices by status, so outstanding vs paid is
  visible at a glance.
  """
  def freight_invoice_aging do
    from(i in Invoice,
      group_by: i.status,
      select: %{status: i.status, count: count(i.id), total: sum(i.total_amount)}
    )
    |> Repo.all()
  end
end
