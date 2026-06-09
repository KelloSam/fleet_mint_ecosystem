defmodule FleetMintWeb.FreightOrderController do
  use FleetMintWeb, :controller
  alias FleetMint.Freight
  alias FleetMint.Freight.Order

  def index(conn, params) do
    orders = Freight.list_orders(status: params["status"], client_id: params["client_id"])
    render(conn, :index, orders: orders)
  end

  def new(conn, params) do
    changeset = Freight.change_order(%Order{})
    clients = Freight.list_clients(status: "active")
    render(conn, :new, changeset: changeset, clients: clients,
                       prefill_client: params["client_id"])
  end

  def create(conn, %{"order" => params}) do
    user_id = conn.assigns[:current_user].id
    case Freight.create_order(params, user_id) do
      {:ok, order} ->
        conn |> put_flash(:info, "Order #{order.order_reference} created.") |> redirect(to: ~p"/freight/orders/#{order}")
      {:error, changeset} ->
        clients = Freight.list_clients(status: "active")
        render(conn, :new, changeset: changeset, clients: clients, prefill_client: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    order = Freight.get_order!(id)
    render(conn, :show, order: order)
  end

  def edit(conn, %{"id" => id}) do
    order = Freight.get_order!(id)
    changeset = Freight.change_order(order)
    clients = Freight.list_clients(status: "active")
    trips = Freight.list_trips(status: "scheduled")
    render(conn, :edit, order: order, changeset: changeset, clients: clients, trips: trips)
  end

  def update(conn, %{"id" => id, "order" => params}) do
    order = Freight.get_order!(id)
    case Freight.update_order(order, params) do
      {:ok, order} ->
        conn |> put_flash(:info, "Order updated.") |> redirect(to: ~p"/freight/orders/#{order}")
      {:error, changeset} ->
        clients = Freight.list_clients(status: "active")
        trips = Freight.list_trips(status: "scheduled")
        render(conn, :edit, order: order, changeset: changeset, clients: clients, trips: trips)
    end
  end

  def delete(conn, %{"id" => id}) do
    order = Freight.get_order!(id)
    {:ok, _} = Freight.delete_order(order)
    conn |> put_flash(:info, "Order deleted.") |> redirect(to: ~p"/freight/orders")
  end
end
