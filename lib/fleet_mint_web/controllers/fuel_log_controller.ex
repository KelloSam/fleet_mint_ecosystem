defmodule FleetMintWeb.FuelLogController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Fleet.FuelLog
  alias FleetMint.HR
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    page = FleetMint.Pagination.parse_page(params)

    paged =
      Fleet.list_fuel_logs_paginated(page, organisation_id: conn.assigns.organisation_scope)

    render(conn, :index, paged: paged)
  end

  def new(conn, _params) do
    changeset = Fleet.change_fuel_log(%FuelLog{})

    render(conn, :new,
      changeset: changeset,
      vehicles: allowed_vehicles(conn),
      drivers: allowed_drivers(conn)
    )
  end

  def create(conn, %{"fuel_log" => params}) do
    vehicles = allowed_vehicles(conn)
    params = Map.put(params, "recorded_by_id", conn.assigns.current_user.id)

    if vehicle_allowed?(vehicles, params["vehicle_id"]) do
      case Fleet.create_fuel_log(params) do
        {:ok, log} ->
          conn |> put_flash(:info, "Fuel log saved.") |> redirect(to: ~p"/fuel_logs/#{log}")

        {:error, changeset} ->
          render(conn, :new,
            changeset: changeset,
            vehicles: vehicles,
            drivers: allowed_drivers(conn)
          )
      end
    else
      changeset = Fleet.change_fuel_log(%FuelLog{})

      conn
      |> put_flash(:error, "That vehicle is not available to you.")
      |> render(:new, changeset: changeset, vehicles: vehicles, drivers: allowed_drivers(conn))
    end
  end

  def show(conn, %{"id" => id}) do
    fuel_log = Fleet.get_fuel_log!(id)

    with_organisation_access(conn, fuel_log.vehicle, ~p"/fuel_logs", fn conn ->
      render(conn, :show, fuel_log: fuel_log)
    end)
  end

  def edit(conn, %{"id" => id}) do
    fuel_log = Fleet.get_fuel_log!(id)

    with_organisation_access(conn, fuel_log.vehicle, ~p"/fuel_logs", fn conn ->
      changeset = Fleet.change_fuel_log(fuel_log)

      render(conn, :edit,
        fuel_log: fuel_log,
        changeset: changeset,
        vehicles: allowed_vehicles(conn),
        drivers: allowed_drivers(conn)
      )
    end)
  end

  def update(conn, %{"id" => id, "fuel_log" => params}) do
    fuel_log = Fleet.get_fuel_log!(id)

    with_organisation_access(conn, fuel_log.vehicle, ~p"/fuel_logs", fn conn ->
      case Fleet.update_fuel_log(fuel_log, params) do
        {:ok, log} ->
          conn |> put_flash(:info, "Fuel log updated.") |> redirect(to: ~p"/fuel_logs/#{log}")

        {:error, changeset} ->
          render(conn, :edit,
            fuel_log: fuel_log,
            changeset: changeset,
            vehicles: allowed_vehicles(conn),
            drivers: allowed_drivers(conn)
          )
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    fuel_log = Fleet.get_fuel_log!(id)

    with_organisation_access(conn, fuel_log.vehicle, ~p"/fuel_logs", fn conn ->
      {:ok, _} = Fleet.delete_fuel_log(fuel_log)
      conn |> put_flash(:info, "Fuel log deleted.") |> redirect(to: ~p"/fuel_logs")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp allowed_vehicles(conn),
    do: Fleet.list_vehicles(organisation_id: conn.assigns.organisation_scope)

  defp allowed_drivers(conn),
    do: HR.list_drivers(organisation_id: conn.assigns.organisation_scope)

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
      |> put_flash(:error, "That fuel log belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
