defmodule FleetMintWeb.FreightOrderController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Order
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    orders =
      Cargo.list_orders(
        status: params["status"],
        client_id: params["client_id"],
        organisation_id: conn.assigns.organisation_scope
      )
    render(conn, :index, orders: orders)
  end

  def new(conn, params) do
    changeset = Cargo.change_order(%Order{})
    clients = allowed_clients(conn)
    render(conn, :new, changeset: changeset, clients: clients,
                       prefill_client: params["client_id"])
  end

  def create(conn, %{"order" => params}) do
    user_id = conn.assigns[:current_user].id
    clients = allowed_clients(conn)

    if client_allowed?(clients, params["client_id"]) do
      case Cargo.create_order(params, user_id) do
        {:ok, order} ->
          conn |> put_flash(:info, "Order #{order.order_reference} created.") |> redirect(to: ~p"/freight/orders/#{order}")
        {:error, changeset} ->
          render(conn, :new, changeset: changeset, clients: clients, prefill_client: nil)
      end
    else
      changeset = Cargo.change_order(%Order{})
      conn
      |> put_flash(:error, "That client is not available to you.")
      |> render(:new, changeset: changeset, clients: clients, prefill_client: nil)
    end
  end

  def show(conn, %{"id" => id}) do
    order = Cargo.get_order!(id)

    with_organisation_access(conn, order.client, ~p"/freight/orders", fn conn ->
      render(conn, :show, order: order)
    end)
  end

  def edit(conn, %{"id" => id}) do
    order = Cargo.get_order!(id)

    with_organisation_access(conn, order.client, ~p"/freight/orders", fn conn ->
      changeset = Cargo.change_order(order)
      clients = allowed_clients(conn)
      trips = Cargo.list_trips(status: "scheduled", organisation_id: conn.assigns.organisation_scope)
      render(conn, :edit, order: order, changeset: changeset, clients: clients, trips: trips)
    end)
  end

  def update(conn, %{"id" => id, "order" => params}) do
    order = Cargo.get_order!(id)

    with_organisation_access(conn, order.client, ~p"/freight/orders", fn conn ->
      case Cargo.update_order(order, params) do
        {:ok, order} ->
          conn |> put_flash(:info, "Order updated.") |> redirect(to: ~p"/freight/orders/#{order}")
        {:error, changeset} ->
          clients = allowed_clients(conn)
          trips = Cargo.list_trips(status: "scheduled", organisation_id: conn.assigns.organisation_scope)
          render(conn, :edit, order: order, changeset: changeset, clients: clients, trips: trips)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    order = Cargo.get_order!(id)

    with_organisation_access(conn, order.client, ~p"/freight/orders", fn conn ->
      {:ok, _} = Cargo.delete_order(order)
      conn |> put_flash(:info, "Order deleted.") |> redirect(to: ~p"/freight/orders")
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
      |> put_flash(:error, "That order belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
