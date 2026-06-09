defmodule FleetMintWeb.VehicleController do
  use FleetMintWeb, :controller
  alias FleetMint.Fleet
  alias FleetMint.Fleet.Vehicle

  def index(conn, params) do
    vehicles = Fleet.list_vehicles(type: params["type"], status: params["status"])
    render(conn, :index, vehicles: vehicles, type_filter: params["type"], status_filter: params["status"])
  end

  def new(conn, params) do
    vehicle_type = params["type"] || "bus"
    changeset = Fleet.change_vehicle(%Vehicle{vehicle_type: vehicle_type})
    render(conn, :new, changeset: changeset, vehicle_type: vehicle_type)
  end

  def create(conn, %{"vehicle" => vehicle_params}) do
    case Fleet.create_vehicle(vehicle_params) do
      {:ok, vehicle} ->
        conn
        |> put_flash(:info, "Vehicle #{vehicle.registration_number} added to fleet.")
        |> redirect(to: ~p"/vehicles/#{vehicle}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, vehicle_type: vehicle_params["vehicle_type"] || "bus")
    end
  end

  def show(conn, %{"id" => id}) do
    vehicle = Fleet.get_vehicle!(id)
    render(conn, :show, vehicle: vehicle)
  end

  def edit(conn, %{"id" => id}) do
    vehicle = Fleet.get_vehicle!(id)
    changeset = Fleet.change_vehicle(vehicle)
    render(conn, :edit, vehicle: vehicle, changeset: changeset)
  end

  def update(conn, %{"id" => id, "vehicle" => vehicle_params}) do
    vehicle = Fleet.get_vehicle!(id)
    case Fleet.update_vehicle(vehicle, vehicle_params) do
      {:ok, vehicle} ->
        conn
        |> put_flash(:info, "Vehicle updated.")
        |> redirect(to: ~p"/vehicles/#{vehicle}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, vehicle: vehicle, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    vehicle = Fleet.get_vehicle!(id)
    {:ok, _} = Fleet.delete_vehicle(vehicle)
    conn
    |> put_flash(:info, "Vehicle removed from fleet.")
    |> redirect(to: ~p"/vehicles")
  end
end
