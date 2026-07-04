defmodule FleetMintWeb.FuelLogController do
  use FleetMintWeb, :controller

  alias FleetMint.Fleet
  alias FleetMint.Fleet.FuelLog
  alias FleetMint.Operations

  def index(conn, _params) do
    fuel_logs = Fleet.list_fuel_logs()
    render(conn, :index, fuel_logs: fuel_logs)
  end

  def new(conn, _params) do
    changeset = Fleet.change_fuel_log(%FuelLog{})
    render(conn, :new,
      changeset: changeset,
      vehicles: Fleet.list_vehicles(),
      drivers: Operations.list_drivers()
    )
  end

  def create(conn, %{"fuel_log" => params}) do
    params = Map.put(params, "recorded_by_id", conn.assigns.current_user.id)
    case Fleet.create_fuel_log(params) do
      {:ok, log} ->
        conn |> put_flash(:info, "Fuel log saved.") |> redirect(to: ~p"/fuel_logs/#{log}")
      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          vehicles: Fleet.list_vehicles(),
          drivers: Operations.list_drivers()
        )
    end
  end

  def show(conn, %{"id" => id}) do
    fuel_log = Fleet.get_fuel_log!(id)
    render(conn, :show, fuel_log: fuel_log)
  end

  def edit(conn, %{"id" => id}) do
    fuel_log = Fleet.get_fuel_log!(id)
    changeset = Fleet.change_fuel_log(fuel_log)
    render(conn, :edit,
      fuel_log: fuel_log,
      changeset: changeset,
      vehicles: Fleet.list_vehicles(),
      drivers: Operations.list_drivers()
    )
  end

  def update(conn, %{"id" => id, "fuel_log" => params}) do
    fuel_log = Fleet.get_fuel_log!(id)
    case Fleet.update_fuel_log(fuel_log, params) do
      {:ok, log} ->
        conn |> put_flash(:info, "Fuel log updated.") |> redirect(to: ~p"/fuel_logs/#{log}")
      {:error, changeset} ->
        render(conn, :edit,
          fuel_log: fuel_log,
          changeset: changeset,
          vehicles: Fleet.list_vehicles(),
          drivers: Operations.list_drivers()
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    fuel_log = Fleet.get_fuel_log!(id)
    {:ok, _} = Fleet.delete_fuel_log(fuel_log)
    conn |> put_flash(:info, "Fuel log deleted.") |> redirect(to: ~p"/fuel_logs")
  end
end
