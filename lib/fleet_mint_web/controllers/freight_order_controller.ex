defmodule FleetMintWeb.FreightOrderController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Order

  def index(conn, params) do
    orders = Cargo.list_orders(status: params["status"], client_id: params["client_id"])
    render(conn, :index, orders: orders)
  end

  def new(conn, params) do
    changeset = Cargo.change_order(%Order{})
    clients = Cargo.list_clients(status: "active")
    render(conn, :new, changeset: changeset, clients: clients,
                       prefill_client: params["client_id"])
  end

  def create(conn, %{"order" => params}) do
    user_id = conn.assigns[:current_user].id
    case Cargo.create_order(params, user_id) do
      {:ok, order} ->
        conn |> put_flash(:info, "Order #{order.order_reference} created.") |> redirect(to: ~p"/freight/orders/#{order}")
      {:error, changeset} ->
        clients = Cargo.list_clients(status: "active")
        render(conn, :new, changeset: changeset, clients: clients, prefill_client: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    order = Cargo.get_order!(id)
    render(conn, :show, order: order)
  end

  def edit(conn, %{"id" => id}) do
    order = Cargo.get_order!(id)
    changeset = Cargo.change_order(order)
    clients = Cargo.list_clients(status: "active")
    trips = Cargo.list_trips(status: "scheduled")
    render(conn, :edit, order: order, changeset: changeset, clients: clients, trips: trips)
  end

  def update(conn, %{"id" => id, "order" => params}) do
    order = Cargo.get_order!(id)
    case Cargo.update_order(order, params) do
      {:ok, order} ->
        conn |> put_flash(:info, "Order updated.") |> redirect(to: ~p"/freight/orders/#{order}")
      {:error, changeset} ->
        clients = Cargo.list_clients(status: "active")
        trips = Cargo.list_trips(status: "scheduled")
        render(conn, :edit, order: order, changeset: changeset, clients: clients, trips: trips)
    end
  end

  def delete(conn, %{"id" => id}) do
    order = Cargo.get_order!(id)
    {:ok, _} = Cargo.delete_order(order)
    conn |> put_flash(:info, "Order deleted.") |> redirect(to: ~p"/freight/orders")
  end
end
