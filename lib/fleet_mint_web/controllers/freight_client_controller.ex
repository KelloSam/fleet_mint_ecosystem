defmodule FleetMintWeb.FreightClientController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Client

  def index(conn, params) do
    clients = Cargo.list_clients(status: params["status"])
    render(conn, :index, clients: clients)
  end

  def new(conn, _params) do
    changeset = Cargo.change_client(%Client{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"client" => params}) do
    case Cargo.create_client(params) do
      {:ok, client} ->
        conn |> put_flash(:info, "Client #{client.company_name} created.") |> redirect(to: ~p"/freight/clients/#{client}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    client = Cargo.get_client_with_orders!(id)
    render(conn, :show, client: client)
  end

  def edit(conn, %{"id" => id}) do
    client = Cargo.get_client!(id)
    changeset = Cargo.change_client(client)
    render(conn, :edit, client: client, changeset: changeset)
  end

  def update(conn, %{"id" => id, "client" => params}) do
    client = Cargo.get_client!(id)
    case Cargo.update_client(client, params) do
      {:ok, client} ->
        conn |> put_flash(:info, "Client updated.") |> redirect(to: ~p"/freight/clients/#{client}")
      {:error, changeset} ->
        render(conn, :edit, client: client, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    client = Cargo.get_client!(id)
    {:ok, _} = Cargo.delete_client(client)
    conn |> put_flash(:info, "Client deleted.") |> redirect(to: ~p"/freight/clients")
  end
end
