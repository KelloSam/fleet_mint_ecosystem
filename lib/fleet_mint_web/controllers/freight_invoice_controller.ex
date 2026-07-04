defmodule FleetMintWeb.FreightInvoiceController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Invoice

  def index(conn, params) do
    invoices = Cargo.list_invoices(status: params["status"], client_id: params["client_id"])
    render(conn, :index, invoices: invoices)
  end

  def new(conn, params) do
    changeset = Cargo.change_invoice(%Invoice{})
    clients = Cargo.list_clients(status: "active")
    trips = Cargo.list_trips(status: "delivered")
    render(conn, :new, changeset: changeset, clients: clients, trips: trips,
                       prefill_trip: params["trip_id"])
  end

  def create(conn, %{"invoice" => params}) do
    user_id = conn.assigns[:current_user].id
    case Cargo.create_invoice(params, user_id) do
      {:ok, invoice} ->
        conn |> put_flash(:info, "Invoice #{invoice.invoice_number} created.") |> redirect(to: ~p"/freight/invoices/#{invoice}")
      {:error, changeset} ->
        clients = Cargo.list_clients(status: "active")
        trips = Cargo.list_trips(status: "delivered")
        render(conn, :new, changeset: changeset, clients: clients, trips: trips, prefill_trip: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    invoice = Cargo.get_invoice!(id)
    render(conn, :show, invoice: invoice)
  end

  def edit(conn, %{"id" => id}) do
    invoice = Cargo.get_invoice!(id)
    changeset = Cargo.change_invoice(invoice)
    clients = Cargo.list_clients(status: "active")
    trips = Cargo.list_trips(status: "delivered")
    render(conn, :edit, invoice: invoice, changeset: changeset, clients: clients, trips: trips)
  end

  def update(conn, %{"id" => id, "invoice" => params}) do
    invoice = Cargo.get_invoice!(id)
    case Cargo.update_invoice(invoice, params) do
      {:ok, invoice} ->
        conn |> put_flash(:info, "Invoice updated.") |> redirect(to: ~p"/freight/invoices/#{invoice}")
      {:error, changeset} ->
        clients = Cargo.list_clients(status: "active")
        trips = Cargo.list_trips(status: "delivered")
        render(conn, :edit, invoice: invoice, changeset: changeset, clients: clients, trips: trips)
    end
  end

  def delete(conn, %{"id" => id}) do
    invoice = Cargo.get_invoice!(id)
    {:ok, _} = Cargo.delete_invoice(invoice)
    conn |> put_flash(:info, "Invoice deleted.") |> redirect(to: ~p"/freight/invoices")
  end
end
