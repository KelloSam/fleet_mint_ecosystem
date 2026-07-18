defmodule FleetMintWeb.OperatorController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Fleet.Operator
  alias FleetMint.Transport.Routes
  alias FleetMint.Identity.Authorization

  # Creating an Operator (Fleet.create_operator/1 creates its Organisation
  # too - see identity/organisation.ex) is onboarding a brand new tenant,
  # not managing an existing one. That's Miway's call, not any tenant's
  # own manager/admin, regardless of which organisation they belong to.
  plug :require_platform_admin when action in [:new, :create]
  plug :require_admin_or_manager when action in [:edit, :update, :delete]

  def index(conn, _params) do
    operators = Routes.list_operators_with_route_counts(organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, operators: operators)
  end

  def show(conn, %{"id" => id}) do
    operator = Routes.get_operator_with_routes!(id)

    with_organisation_access(conn, operator.organisation_id, ~p"/operators", fn conn ->
      render(conn, :show, operator: operator)
    end)
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

    with_organisation_access(conn, op.organisation_id, ~p"/operators", fn conn ->
      changeset = Fleet.change_operator(op)
      render(conn, :edit, operator: op, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "operator" => params}) do
    op = Fleet.get_operator!(id)

    with_organisation_access(conn, op.organisation_id, ~p"/operators", fn conn ->
      case Fleet.update_operator(op, params) do
        {:ok, op} ->
          conn |> put_flash(:info, "#{op.name} updated.") |> redirect(to: ~p"/operators")
        {:error, changeset} ->
          render(conn, :edit, operator: op, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    op = Fleet.get_operator!(id)

    with_organisation_access(conn, op.organisation_id, ~p"/operators", fn conn ->
      {:ok, _} = Fleet.delete_operator(op)
      conn |> put_flash(:info, "#{op.name} archived.") |> redirect(to: ~p"/operators")
    end)
  end

  defp require_platform_admin(conn, _opts) do
    if Authorization.platform_admin?(conn.assigns.current_user) do
      conn
    else
      conn |> put_flash(:error, "Only Miway platform administrators can register a new organisation.") |> redirect(to: ~p"/operators") |> halt()
    end
  end

  defp require_admin_or_manager(conn, _opts) do
    if Authorization.authorized?(conn.assigns.current_user, ["platform_admin", "tenant_admin", "manager"]) do
      conn
    else
      conn |> put_flash(:error, "Not authorised.") |> redirect(to: ~p"/operators") |> halt()
    end
  end

  defp with_organisation_access(conn, organisation_id, fallback_path, fun) do
    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That operator belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
