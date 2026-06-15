defmodule FleetMintWeb.VehicleMaintenanceController do
  use FleetMintWeb, :controller

  alias FleetMint.Fleet
  alias FleetMint.Fleet.VehicleMaintenance

  def index(conn, _params) do
    maintenances = Fleet.list_maintenances()
    render(conn, :index, maintenances: maintenances)
  end

  def new(conn, _params) do
    changeset = Fleet.change_maintenance(%VehicleMaintenance{})
    render(conn, :new, changeset: changeset, vehicles: Fleet.list_vehicles())
  end

  def create(conn, %{"vehicle_maintenance" => params}) do
    params = Map.put(params, "recorded_by_id", conn.assigns.current_user.id)
    case Fleet.create_maintenance(params) do
      {:ok, m} ->
        conn |> put_flash(:info, "Maintenance record saved.") |> redirect(to: ~p"/maintenances/#{m}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset, vehicles: Fleet.list_vehicles())
    end
  end

  def show(conn, %{"id" => id}) do
    maintenance = Fleet.get_maintenance!(id)
    render(conn, :show, maintenance: maintenance)
  end

  def edit(conn, %{"id" => id}) do
    maintenance = Fleet.get_maintenance!(id)
    changeset = Fleet.change_maintenance(maintenance)
    render(conn, :edit, maintenance: maintenance, changeset: changeset, vehicles: Fleet.list_vehicles())
  end

  def update(conn, %{"id" => id, "vehicle_maintenance" => params}) do
    maintenance = Fleet.get_maintenance!(id)
    case Fleet.update_maintenance(maintenance, params) do
      {:ok, m} ->
        conn |> put_flash(:info, "Record updated.") |> redirect(to: ~p"/maintenances/#{m}")
      {:error, changeset} ->
        render(conn, :edit, maintenance: maintenance, changeset: changeset, vehicles: Fleet.list_vehicles())
    end
  end

  def delete(conn, %{"id" => id}) do
    maintenance = Fleet.get_maintenance!(id)
    {:ok, _} = Fleet.delete_maintenance(maintenance)
    conn |> put_flash(:info, "Record deleted.") |> redirect(to: ~p"/maintenances")
  end
end
