defmodule FleetMintWeb.BusController do
  use FleetMintWeb, :controller

  alias FleetMint.Fleet
  alias FleetMint.Fleet.Bus

  def index(conn, params) do
    status = Map.get(params, "status")
    buses = if status && status != "", do: Fleet.list_buses_by_status(status), else: Fleet.list_buses()
    render(conn, :index, buses: buses, filter_status: status || "")
  end

  def new(conn, _params) do
    changeset = Fleet.change_bus(%Bus{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"bus" => bus_params}) do
    case Fleet.create_bus(bus_params) do
      {:ok, bus} ->
        conn
        |> put_flash(:info, "Bus #{bus.registration_number} added successfully.")
        |> redirect(to: ~p"/buses/#{bus}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    bus = Fleet.get_bus!(id)
    render(conn, :show, bus: bus)
  end

  def edit(conn, %{"id" => id}) do
    bus = Fleet.get_bus!(id)
    changeset = Fleet.change_bus(bus)
    render(conn, :edit, bus: bus, changeset: changeset)
  end

  def update(conn, %{"id" => id, "bus" => bus_params}) do
    bus = Fleet.get_bus!(id)

    case Fleet.update_bus(bus, bus_params) do
      {:ok, bus} ->
        conn
        |> put_flash(:info, "Bus #{bus.registration_number} updated successfully.")
        |> redirect(to: ~p"/buses/#{bus}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, bus: bus, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    bus = Fleet.get_bus!(id)
    {:ok, _bus} = Fleet.delete_bus(bus)

    conn
    |> put_flash(:info, "Bus #{bus.registration_number} removed.")
    |> redirect(to: ~p"/buses")
  end
end
