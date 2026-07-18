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
    %Order{} |> Order.changeset(attrs) |> validate_trip_assignment() |> Repo.insert()
  end

  def update_order(%Order{} = order, attrs) do
    order |> Order.changeset(attrs) |> validate_trip_assignment() |> Repo.update()
  end

  def assign_order_to_trip(%Order{} = order, trip_id) do
    order
    |> Order.changeset(%{assigned_trip_id: trip_id, status: "assigned"})
    |> validate_trip_assignment()
    |> Repo.update()
  end

  # Guards against two ways an order/trip assignment can be wrong even
  # though both records individually validate fine: the trip's vehicle
  # belongs to a different organisation than the order's own client (the
  # order-edit form's trip dropdown is already organisation-scoped, so
  # this only fires against a tampered request), or the trip's vehicle
  # doesn't have enough remaining payload capacity for this order on top
  # of what's already assigned to it. Runs on every create/update path
  # (including assign_order_to_trip/2) rather than only the controller's
  # usual entry point, so it can't be bypassed by calling a different
  # function.
  defp validate_trip_assignment(changeset) do
    case Ecto.Changeset.get_field(changeset, :assigned_trip_id) do
      nil ->
        changeset

      trip_id ->
        trip = Trip |> Repo.get(trip_id) |> Repo.preload(vehicle: [:truck_profile])
        client_id = Ecto.Changeset.get_field(changeset, :client_id)
        client = client_id && Repo.get(Client, client_id)

        cond do
          is_nil(trip) ->
            Ecto.Changeset.add_error(changeset, :assigned_trip_id, "does not exist")

          is_nil(client) ->
            changeset

          is_nil(trip.vehicle) or is_nil(trip.vehicle.organisation_id) ->
            Ecto.Changeset.add_error(changeset, :assigned_trip_id, "cannot be assigned - the trip's vehicle has no organisation on record")

          trip.vehicle.organisation_id != client.organisation_id ->
            Ecto.Changeset.add_error(changeset, :assigned_trip_id, "belongs to a different organisation than this order's client")

          true ->
            validate_trip_capacity(changeset, trip)
        end
    end
  end

  defp validate_trip_capacity(changeset, %Trip{} = trip) do
    capacity = trip.vehicle && trip.vehicle.truck_profile && trip.vehicle.truck_profile.payload_capacity_tons

    if is_nil(capacity) do
      # No capacity on record for this vehicle - nothing to check against,
      # so don't block on data that was never captured.
      changeset
    else
      order_id = Ecto.Changeset.get_field(changeset, :id)
      this_weight = Ecto.Changeset.get_field(changeset, :weight_tons) || Decimal.new(0)

      already_assigned =
        Order
        |> where([o], o.assigned_trip_id == ^trip.id and o.status not in ["delivered", "cancelled"])
        |> Repo.all()
        |> Enum.reject(&(&1.id == order_id))
        |> Enum.reduce(Decimal.new(0), fn o, acc -> Decimal.add(acc, o.weight_tons || Decimal.new(0)) end)

      total = Decimal.add(already_assigned, this_weight)

      if Decimal.compare(total, capacity) == :gt do
        Ecto.Changeset.add_error(
          changeset,
          :assigned_trip_id,
          "would exceed the vehicle's payload capacity of #{capacity} tons (#{already_assigned} tons already assigned to this trip)"
        )
      else
        changeset
      end
    end
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

  @doc """
  Moving a trip forward doesn't just change the trip's own status - its
  assigned orders were silently left behind before this: a trip could go
  all the way to "delivered" while every order riding on it still showed
  "assigned" forever. Cancelling a trip releases its still-open orders
  (unassigned, back to "pending") rather than cancelling them outright -
  the truck may have broken down, but the cargo usually still needs to
  move on a different trip. Orders already "delivered" or "cancelled" are
  left alone either way.
  """
  def update_trip_status(%Trip{} = trip, status) do
    extra = case status do
      "in_transit" -> %{actual_departure: NaiveDateTime.utc_now()}
      "delivered" -> %{actual_arrival: NaiveDateTime.utc_now()}
      _ -> %{}
    end

    changeset = Trip.changeset(trip, Map.merge(%{status: status}, extra))

    Ecto.Multi.new()
    |> Ecto.Multi.update(:trip, changeset)
    |> Ecto.Multi.run(:cascade_order_status, fn _repo, %{trip: updated} -> cascade_order_status(updated) end)
    |> Repo.transaction()
    |> unwrap_multi(:trip)
  end

  defp cascade_order_status(%Trip{status: "cancelled"} = trip) do
    {count, _} =
      Order
      |> where([o], o.assigned_trip_id == ^trip.id and o.status not in ["delivered", "cancelled"])
      |> Repo.update_all(set: [assigned_trip_id: nil, status: "pending"])

    {:ok, count}
  end

  defp cascade_order_status(%Trip{status: status} = trip) when status in ~w(loading in_transit delivered) do
    {count, _} =
      Order
      |> where([o], o.assigned_trip_id == ^trip.id and o.status not in ["delivered", "cancelled"])
      |> Repo.update_all(set: [status: status])

    {:ok, count}
  end

  defp cascade_order_status(_trip), do: {:ok, 0}

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
