defmodule FleetMintWeb.VehicleController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Fleet.Vehicle
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    vehicles =
      Fleet.list_vehicles(
        type: params["type"],
        status: params["status"],
        organisation_id: conn.assigns.organisation_scope
      )
    render(conn, :index, vehicles: vehicles, type_filter: params["type"], status_filter: params["status"])
  end

  def new(conn, params) do
    vehicle_type = params["type"] || "bus"
    changeset = Fleet.change_vehicle(%Vehicle{vehicle_type: vehicle_type})
    render(conn, :new, changeset: changeset, vehicle_type: vehicle_type)
  end

  def create(conn, %{"vehicle" => vehicle_params}) do
    vehicle_params = force_organisation_scope(vehicle_params, conn.assigns.organisation_scope)

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

    with_organisation_access(conn, vehicle.organisation_id, ~p"/vehicles", fn conn ->
      render(conn, :show, vehicle: vehicle)
    end)
  end

  def edit(conn, %{"id" => id}) do
    vehicle = Fleet.get_vehicle!(id)

    with_organisation_access(conn, vehicle.organisation_id, ~p"/vehicles", fn conn ->
      changeset = Fleet.change_vehicle(vehicle)
      render(conn, :edit, vehicle: vehicle, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "vehicle" => vehicle_params}) do
    vehicle = Fleet.get_vehicle!(id)

    with_organisation_access(conn, vehicle.organisation_id, ~p"/vehicles", fn conn ->
      case Fleet.update_vehicle(vehicle, vehicle_params) do
        {:ok, vehicle} ->
          conn
          |> put_flash(:info, "Vehicle updated.")
          |> redirect(to: ~p"/vehicles/#{vehicle}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, vehicle: vehicle, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    vehicle = Fleet.get_vehicle!(id)

    with_organisation_access(conn, vehicle.organisation_id, ~p"/vehicles", fn conn ->
      {:ok, _} = Fleet.delete_vehicle(vehicle)
      conn
      |> put_flash(:info, "Vehicle archived and removed from active fleet.")
      |> redirect(to: ~p"/vehicles")
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
      |> put_flash(:error, "That vehicle belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
