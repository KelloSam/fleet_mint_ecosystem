defmodule FleetMintWeb.VehicleMaintenanceController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Fleet.VehicleMaintenance
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    maintenances = Fleet.list_maintenances(organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, maintenances: maintenances)
  end

  def new(conn, _params) do
    changeset = Fleet.change_maintenance(%VehicleMaintenance{})
    render(conn, :new, changeset: changeset, vehicles: allowed_vehicles(conn))
  end

  def create(conn, %{"vehicle_maintenance" => params}) do
    vehicles = allowed_vehicles(conn)
    params = Map.put(params, "recorded_by_id", conn.assigns.current_user.id)

    if vehicle_allowed?(vehicles, params["vehicle_id"]) do
      case Fleet.create_maintenance(params) do
        {:ok, m} ->
          conn
          |> put_flash(:info, "Maintenance record saved.")
          |> redirect(to: ~p"/maintenances/#{m}")

        {:error, changeset} ->
          render(conn, :new, changeset: changeset, vehicles: vehicles)
      end
    else
      changeset = Fleet.change_maintenance(%VehicleMaintenance{})

      conn
      |> put_flash(:error, "That vehicle is not available to you.")
      |> render(:new, changeset: changeset, vehicles: vehicles)
    end
  end

  def show(conn, %{"id" => id}) do
    maintenance = Fleet.get_maintenance!(id)

    with_organisation_access(conn, maintenance.vehicle, ~p"/maintenances", fn conn ->
      render(conn, :show, maintenance: maintenance)
    end)
  end

  def edit(conn, %{"id" => id}) do
    maintenance = Fleet.get_maintenance!(id)

    with_organisation_access(conn, maintenance.vehicle, ~p"/maintenances", fn conn ->
      changeset = Fleet.change_maintenance(maintenance)

      render(conn, :edit,
        maintenance: maintenance,
        changeset: changeset,
        vehicles: allowed_vehicles(conn)
      )
    end)
  end

  def update(conn, %{"id" => id, "vehicle_maintenance" => params}) do
    maintenance = Fleet.get_maintenance!(id)

    with_organisation_access(conn, maintenance.vehicle, ~p"/maintenances", fn conn ->
      case Fleet.update_maintenance(maintenance, params) do
        {:ok, m} ->
          conn |> put_flash(:info, "Record updated.") |> redirect(to: ~p"/maintenances/#{m}")

        {:error, changeset} ->
          render(conn, :edit,
            maintenance: maintenance,
            changeset: changeset,
            vehicles: allowed_vehicles(conn)
          )
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    maintenance = Fleet.get_maintenance!(id)

    with_organisation_access(conn, maintenance.vehicle, ~p"/maintenances", fn conn ->
      {:ok, _} = Fleet.delete_maintenance(maintenance)
      conn |> put_flash(:info, "Record deleted.") |> redirect(to: ~p"/maintenances")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp allowed_vehicles(conn),
    do: Fleet.list_vehicles(organisation_id: conn.assigns.organisation_scope)

  defp vehicle_allowed?(vehicles, vehicle_id) do
    vehicle_id = to_string(vehicle_id)
    Enum.any?(vehicles, &(to_string(&1.id) == vehicle_id))
  end

  defp with_organisation_access(conn, vehicle, fallback_path, fun) do
    organisation_id = vehicle && vehicle.organisation_id

    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That maintenance record belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
