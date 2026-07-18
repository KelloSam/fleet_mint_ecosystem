defmodule FleetMint.Cargo do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Accounting
  alias FleetMint.Cargo.{Client, Order, Trip, TripMilestone, Invoice}

  # ── Clients ───────────────────────────────────────────────────────────────

  def list_clients(opts \\ []) do
    Client
    |> maybe_filter_status(opts[:status])
    |> maybe_filter_organisation(opts[:organisation_id])
    |> order_by([c], c.company_name)
    |> Repo.all()
  end

  def get_client!(id), do: Repo.get!(Client, id)
  def get_client_with_orders!(id), do: Repo.get!(Client, id) |> Repo.preload(orders: [:assigned_trip])

  def create_client(attrs) do
    %Client{} |> Client.changeset(attrs) |> Repo.insert()
  end

  def update_client(%Client{} = client, attrs) do
    client |> Client.changeset(attrs) |> Repo.update()
  end

  def delete_client(%Client{} = client), do: Repo.delete(client)
  def change_client(%Client{} = client, attrs \\ %{}), do: Client.changeset(client, attrs)

  # ── Orders ────────────────────────────────────────────────────────────────

  def list_orders(opts \\ []) do
    Order
    |> maybe_filter_status(opts[:status])
    |> maybe_filter_client(opts[:client_id])
    |> maybe_filter_order_organisation(opts[:organisation_id])
    |> preload([:client, :assigned_trip, :created_by])
    |> order_by([o], [desc: o.inserted_at])
    |> Repo.all()
  end

  def get_order!(id), do: Repo.get!(Order, id) |> Repo.preload([:client, :assigned_trip])
  def get_order_by_reference!(ref), do: Repo.get_by!(Order, order_reference: ref)

  def create_order(attrs, user_id \\ nil) do
    attrs = if user_id, do: Map.put(attrs, "created_by_id", user_id), else: attrs
    %Order{} |> Order.changeset(attrs) |> Repo.insert()
  end

  def update_order(%Order{} = order, attrs) do
    order |> Order.changeset(attrs) |> Repo.update()
  end

  def assign_order_to_trip(%Order{} = order, trip_id) do
    order |> Order.changeset(%{assigned_trip_id: trip_id, status: "assigned"}) |> Repo.update()
  end

  def delete_order(%Order{} = order), do: Repo.delete(order)
  def change_order(%Order{} = order, attrs \\ %{}), do: Order.changeset(order, attrs)

  def pending_orders_count do
    Repo.aggregate(from(o in Order, where: o.status == "pending"), :count)
  end

  # ── Trips ─────────────────────────────────────────────────────────────────

  def list_trips(opts \\ []) do
    Trip
    |> maybe_filter_status(opts[:status])
    |> maybe_filter_trip_organisation(opts[:organisation_id])
    |> preload([:vehicle, :driver, :co_driver, orders: [:client]])
    |> order_by([t], [desc: t.planned_departure])
    |> Repo.all()
  end

  def get_trip!(id), do: Repo.get!(Trip, id) |> Repo.preload([:vehicle, :driver, :co_driver, :milestones, orders: [:client]])
  def get_trip_by_reference!(ref), do: Repo.get_by!(Trip, trip_reference: ref) |> Repo.preload([:vehicle, :driver, :milestones, orders: [:client]])

  def create_trip(attrs, user_id \\ nil) do
    attrs = if user_id, do: Map.put(attrs, "created_by_id", user_id), else: attrs
    changeset = Trip.changeset(%Trip{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:trip, changeset)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{trip: trip} ->
      maybe_record_trip_expense(trip)
    end)
    |> Repo.transaction()
    |> unwrap_multi(:trip)
  end

  def update_trip(%Trip{} = trip, attrs) do
    changeset = Trip.changeset(trip, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:trip, changeset)
    |> Ecto.Multi.run(:expense_entry, fn _repo, %{trip: updated} ->
      sync_trip_expense(updated)
    end)
    |> Repo.transaction()
    |> unwrap_multi(:trip)
  end

  def update_trip_status(%Trip{} = trip, status) do
    extra = case status do
      "in_transit" -> %{actual_departure: NaiveDateTime.utc_now()}
      "delivered" -> %{actual_arrival: NaiveDateTime.utc_now()}
      _ -> %{}
    end
    trip |> Trip.changeset(Map.merge(%{status: status}, extra)) |> Repo.update()
  end

  def delete_trip(%Trip{} = trip), do: Repo.delete(trip)
  def change_trip(%Trip{} = trip, attrs \\ %{}), do: Trip.changeset(trip, attrs)

  def active_trips_count do
    Repo.aggregate(from(t in Trip, where: t.status in ["loading", "in_transit"]), :count)
  end

  # ── Trip Milestones ───────────────────────────────────────────────────────

  def add_milestone(%Trip{} = trip, attrs) do
    attrs = Map.merge(attrs, %{"trip_id" => trip.id, "event_time" => attrs["event_time"] || NaiveDateTime.utc_now()})
    %TripMilestone{} |> TripMilestone.changeset(attrs) |> Repo.insert()
  end

  def list_milestones(trip_id) do
    TripMilestone
    |> where([m], m.trip_id == ^trip_id)
    |> order_by([m], m.event_time)
    |> Repo.all()
  end

  # ── Invoices ──────────────────────────────────────────────────────────────

  def list_invoices(opts \\ []) do
    Invoice
    |> maybe_filter_status(opts[:status])
    |> maybe_filter_client(opts[:client_id])
    |> maybe_filter_invoice_organisation(opts[:organisation_id])
    |> preload([:client, :trip])
    |> order_by([i], [desc: i.invoice_date])
    |> Repo.all()
  end

  def get_invoice!(id), do: Repo.get!(Invoice, id) |> Repo.preload([:client, :trip])

  def create_invoice(attrs, user_id \\ nil) do
    attrs = if user_id, do: Map.put(attrs, "created_by_id", user_id), else: attrs
    %Invoice{} |> Invoice.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates an invoice. No cash has moved unless this update transitions
  `status` into `"paid"` — in that case, and only the first time, a matching
  revenue ledger entry is written for `total_amount`.
  """
  def update_invoice(%Invoice{} = invoice, attrs) do
    was_paid = invoice.status == "paid"
    changeset = Invoice.changeset(invoice, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:invoice, changeset)
    |> Ecto.Multi.run(:ledger_entry, fn _repo, %{invoice: updated} ->
      maybe_record_invoice_payment(was_paid, updated)
    end)
    |> Repo.transaction()
    |> unwrap_multi(:invoice)
  end

  def mark_invoice_paid(%Invoice{} = invoice, payment_ref) do
    update_invoice(invoice, %{
      status: "paid",
      payment_date: Date.utc_today(),
      payment_reference: payment_ref
    })
  end

  def change_invoice(%Invoice{} = invoice, attrs \\ %{}), do: Invoice.changeset(invoice, attrs)

  def delete_invoice(%Invoice{} = invoice), do: Repo.delete(invoice)

  def outstanding_revenue do
    from(i in Invoice,
      where: i.status in ["issued", "overdue"],
      select: sum(i.total_amount)
    ) |> Repo.one() || Decimal.new(0)
  end

  # ── Private ───────────────────────────────────────────────────────────────

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [x], x.status == ^status)

  defp maybe_filter_client(query, nil), do: query
  defp maybe_filter_client(query, id), do: where(query, [x], x.client_id == ^id)

  defp maybe_filter_organisation(query, nil), do: query
  defp maybe_filter_organisation(query, :all), do: query
  defp maybe_filter_organisation(query, organisation_id), do: where(query, [c], c.organisation_id == ^organisation_id)

  defp maybe_filter_order_organisation(query, nil), do: query
  defp maybe_filter_order_organisation(query, :all), do: query
  defp maybe_filter_order_organisation(query, organisation_id) do
    query
    |> join(:inner, [o], c in assoc(o, :client), as: :client)
    |> where([client: c], c.organisation_id == ^organisation_id)
  end

  defp maybe_filter_trip_organisation(query, nil), do: query
  defp maybe_filter_trip_organisation(query, :all), do: query
  defp maybe_filter_trip_organisation(query, organisation_id) do
    query
    |> join(:inner, [t], v in assoc(t, :vehicle), as: :vehicle)
    |> where([vehicle: v], v.organisation_id == ^organisation_id)
  end

  defp maybe_filter_invoice_organisation(query, nil), do: query
  defp maybe_filter_invoice_organisation(query, :all), do: query
  defp maybe_filter_invoice_organisation(query, organisation_id) do
    query
    |> join(:inner, [i], c in assoc(i, :client), as: :client)
    |> where([client: c], c.organisation_id == ^organisation_id)
  end

  # ── Private ledger helpers ─────────────────────────────────────────────────

  defp maybe_record_invoice_payment(was_paid, %Invoice{status: "paid"} = invoice) when not was_paid do
    case Accounting.entries_for_source("Invoice", invoice.id, "revenue") do
      [] ->
        Accounting.record_entry(%{
          entry_type: "revenue",
          source_type: "Invoice",
          source_id: invoice.id,
          amount: invoice.total_amount,
          reference_number: invoice.payment_reference,
          occurred_at: DateTime.new!(invoice.payment_date || Date.utc_today(), ~T[00:00:00]),
          description: "Payment for invoice #{invoice.invoice_number}"
        })

      [_already_recorded] ->
        {:ok, nil}
    end
  end

  defp maybe_record_invoice_payment(_was_paid, _invoice), do: {:ok, nil}

  defp maybe_record_trip_expense(trip) do
    total = Trip.total_expenses(trip)

    if Decimal.compare(total, Decimal.new(0)) == :gt do
      Accounting.record_entry(%{
        entry_type: "expense",
        source_type: "FreightTrip",
        source_id: trip.id,
        amount: total,
        description: "Toll and other operating expenses for trip #{trip.trip_reference}"
      })
    else
      {:ok, nil}
    end
  end

  defp sync_trip_expense(trip) do
    total = Trip.total_expenses(trip)
    existing = Accounting.entries_for_source("FreightTrip", trip.id, "expense")
    positive? = Decimal.compare(total, Decimal.new(0)) == :gt

    case {existing, positive?} do
      {[], true} -> maybe_record_trip_expense(trip)
      {[], false} -> {:ok, nil}
      {[entry], true} -> entry |> Accounting.change_entry(%{amount: total}) |> Repo.update()
      {[entry], false} -> Repo.delete(entry)
    end
  end

  defp unwrap_multi(multi_result, ok_key) do
    case multi_result do
      {:ok, changes} -> {:ok, Map.fetch!(changes, ok_key)}
      {:error, _failed_step, failed_value, _changes} -> {:error, failed_value}
    end
  end
end
