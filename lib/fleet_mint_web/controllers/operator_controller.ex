defmodule FleetMintWeb.OperatorController do
  use FleetMintWeb, :controller
  alias FleetMint.Fleet
  alias FleetMint.Fleet.Operator

  plug :require_admin when action in [:new, :create, :edit, :update, :delete]

  def index(conn, _params) do
    operators = Fleet.list_operators_with_route_counts()
    render(conn, :index, operators: operators)
  end

  def show(conn, %{"id" => id}) do
    operator = Fleet.get_operator_with_routes!(id)
    render(conn, :show, operator: operator)
  end

  def new(conn, _params) do
    changeset = Fleet.change_operator(%Operator{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"operator" => params}) do
    case Fleet.create_operator(params) do
      {:ok, op} ->
        conn |> put_flash(:info, "#{op.name} added.") |> redirect(to: ~p"/operators")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    op = Fleet.get_operator!(id)
    changeset = Fleet.change_operator(op)
    render(conn, :edit, operator: op, changeset: changeset)
  end

  def update(conn, %{"id" => id, "operator" => params}) do
    op = Fleet.get_operator!(id)
    case Fleet.update_operator(op, params) do
      {:ok, op} ->
        conn |> put_flash(:info, "#{op.name} updated.") |> redirect(to: ~p"/operators")
      {:error, changeset} ->
        render(conn, :edit, operator: op, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    op = Fleet.get_operator!(id)
    {:ok, _} = Fleet.delete_operator(op)
    conn |> put_flash(:info, "#{op.name} removed.") |> redirect(to: ~p"/operators")
  end

  defp require_admin(conn, _opts) do
    if conn.assigns.current_user.role in ["admin", "manager"] do
      conn
    else
      conn |> put_flash(:error, "Not authorised.") |> redirect(to: ~p"/operators") |> halt()
    end
  end
end
