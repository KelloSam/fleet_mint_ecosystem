defmodule FleetMintWeb.FreightInvoiceController do
  use FleetMintWeb, :controller
  alias FleetMint.Freight
  alias FleetMint.Freight.Invoice

  def index(conn, params) do
    invoices = Freight.list_invoices(status: params["status"], client_id: params["client_id"])
    render(conn, :index, invoices: invoices)
  end

  def new(conn, params) do
    changeset = Freight.change_invoice(%Invoice{})
    clients = Freight.list_clients(status: "active")
    trips = Freight.list_trips(status: "delivered")
    render(conn, :new, changeset: changeset, clients: clients, trips: trips,
                       prefill_trip: params["trip_id"])
  end

  def create(conn, %{"invoice" => params}) do
    user_id = conn.assigns[:current_user].id
    case Freight.create_invoice(params, user_id) do
      {:ok, invoice} ->
        conn |> put_flash(:info, "Invoice #{invoice.invoice_number} created.") |> redirect(to: ~p"/freight/invoices/#{invoice}")
      {:error, changeset} ->
        clients = Freight.list_clients(status: "active")
        trips = Freight.list_trips(status: "delivered")
        render(conn, :new, changeset: changeset, clients: clients, trips: trips, prefill_trip: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    invoice = Freight.get_invoice!(id)
    render(conn, :show, invoice: invoice)
  end

  def edit(conn, %{"id" => id}) do
    invoice = Freight.get_invoice!(id)
    changeset = Freight.change_invoice(invoice)
    clients = Freight.list_clients(status: "active")
    trips = Freight.list_trips(status: "delivered")
    render(conn, :edit, invoice: invoice, changeset: changeset, clients: clients, trips: trips)
  end

  def update(conn, %{"id" => id, "invoice" => params}) do
    invoice = Freight.get_invoice!(id)
    case Freight.update_invoice(invoice, params) do
      {:ok, invoice} ->
        conn |> put_flash(:info, "Invoice updated.") |> redirect(to: ~p"/freight/invoices/#{invoice}")
      {:error, changeset} ->
        clients = Freight.list_clients(status: "active")
        trips = Freight.list_trips(status: "delivered")
        render(conn, :edit, invoice: invoice, changeset: changeset, clients: clients, trips: trips)
    end
  end

  def delete(conn, %{"id" => id}) do
    invoice = Freight.get_invoice!(id)
    {:ok, _} = Freight.delete_invoice(invoice)
    conn |> put_flash(:info, "Invoice deleted.") |> redirect(to: ~p"/freight/invoices")
  end
end
