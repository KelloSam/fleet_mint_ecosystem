defmodule FleetMintWeb.FreightInvoiceController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Invoice
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    invoices =
      Cargo.list_invoices(
        status: params["status"],
        client_id: params["client_id"],
        organisation_id: conn.assigns.organisation_scope
      )
    render(conn, :index, invoices: invoices)
  end

  def new(conn, params) do
    changeset = Cargo.change_invoice(%Invoice{})
    clients = allowed_clients(conn)
    trips = Cargo.list_trips(status: "delivered", organisation_id: conn.assigns.organisation_scope)
    render(conn, :new, changeset: changeset, clients: clients, trips: trips,
                       prefill_trip: params["trip_id"])
  end

  def create(conn, %{"invoice" => params}) do
    user_id = conn.assigns[:current_user].id
    clients = allowed_clients(conn)

    if client_allowed?(clients, params["client_id"]) do
      case Cargo.create_invoice(params, user_id) do
        {:ok, invoice} ->
          conn |> put_flash(:info, "Invoice #{invoice.invoice_number} created.") |> redirect(to: ~p"/freight/invoices/#{invoice}")
        {:error, changeset} ->
          trips = Cargo.list_trips(status: "delivered", organisation_id: conn.assigns.organisation_scope)
          render(conn, :new, changeset: changeset, clients: clients, trips: trips, prefill_trip: nil)
      end
    else
      changeset = Cargo.change_invoice(%Invoice{})
      trips = Cargo.list_trips(status: "delivered", organisation_id: conn.assigns.organisation_scope)
      conn
      |> put_flash(:error, "That client is not available to you.")
      |> render(:new, changeset: changeset, clients: clients, trips: trips, prefill_trip: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    invoice = Cargo.get_invoice!(id)

    with_organisation_access(conn, invoice.client, ~p"/freight/invoices", fn conn ->
      render(conn, :show, invoice: invoice)
    end)
  end

  def edit(conn, %{"id" => id}) do
    invoice = Cargo.get_invoice!(id)

    with_organisation_access(conn, invoice.client, ~p"/freight/invoices", fn conn ->
      changeset = Cargo.change_invoice(invoice)
      clients = allowed_clients(conn)
      trips = Cargo.list_trips(status: "delivered", organisation_id: conn.assigns.organisation_scope)
      render(conn, :edit, invoice: invoice, changeset: changeset, clients: clients, trips: trips)
    end)
  end

  def update(conn, %{"id" => id, "invoice" => params}) do
    invoice = Cargo.get_invoice!(id)

    with_organisation_access(conn, invoice.client, ~p"/freight/invoices", fn conn ->
      case Cargo.update_invoice(invoice, params) do
        {:ok, invoice} ->
          conn |> put_flash(:info, "Invoice updated.") |> redirect(to: ~p"/freight/invoices/#{invoice}")
        {:error, changeset} ->
          clients = allowed_clients(conn)
          trips = Cargo.list_trips(status: "delivered", organisation_id: conn.assigns.organisation_scope)
          render(conn, :edit, invoice: invoice, changeset: changeset, clients: clients, trips: trips)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    invoice = Cargo.get_invoice!(id)

    with_organisation_access(conn, invoice.client, ~p"/freight/invoices", fn conn ->
      {:ok, _} = Cargo.delete_invoice(invoice)
      conn |> put_flash(:info, "Invoice deleted.") |> redirect(to: ~p"/freight/invoices")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp allowed_clients(conn), do: Cargo.list_clients(status: "active", organisation_id: conn.assigns.organisation_scope)

  defp client_allowed?(clients, client_id) do
    client_id = to_string(client_id)
    Enum.any?(clients, &(to_string(&1.id) == client_id))
  end

  defp with_organisation_access(conn, client, fallback_path, fun) do
    organisation_id = client && client.organisation_id

    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That invoice belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
