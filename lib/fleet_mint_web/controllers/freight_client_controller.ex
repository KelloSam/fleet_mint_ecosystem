defmodule FleetMintWeb.FreightClientController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Client
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    clients = Cargo.list_clients(status: params["status"], organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, clients: clients)
  end

  def new(conn, _params) do
    changeset = Cargo.change_client(%Client{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"client" => params}) do
    params = force_organisation_scope(params, conn.assigns.organisation_scope)

    case Cargo.create_client(params) do
      {:ok, client} ->
        conn |> put_flash(:info, "Client #{client.company_name} created.") |> redirect(to: ~p"/freight/clients/#{client}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    client = Cargo.get_client_with_orders!(id)

    with_organisation_access(conn, client.organisation_id, ~p"/freight/clients", fn conn ->
      render(conn, :show, client: client)
    end)
  end

  def edit(conn, %{"id" => id}) do
    client = Cargo.get_client!(id)

    with_organisation_access(conn, client.organisation_id, ~p"/freight/clients", fn conn ->
      changeset = Cargo.change_client(client)
      render(conn, :edit, client: client, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "client" => params}) do
    client = Cargo.get_client!(id)

    with_organisation_access(conn, client.organisation_id, ~p"/freight/clients", fn conn ->
      case Cargo.update_client(client, params) do
        {:ok, client} ->
          conn |> put_flash(:info, "Client updated.") |> redirect(to: ~p"/freight/clients/#{client}")
        {:error, changeset} ->
          render(conn, :edit, client: client, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    client = Cargo.get_client!(id)

    with_organisation_access(conn, client.organisation_id, ~p"/freight/clients", fn conn ->
      {:ok, _} = Cargo.delete_client(client)
      conn |> put_flash(:info, "Client deleted.") |> redirect(to: ~p"/freight/clients")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp force_organisation_scope(params, :all), do: params
  defp force_organisation_scope(params, organisation_id), do: Map.put(params, "organisation_id", organisation_id)

  defp with_organisation_access(conn, organisation_id, fallback_path, fun) do
    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That client belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
