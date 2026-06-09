defmodule FleetMintWeb.ScheduleController do
  use FleetMintWeb, :controller
  alias FleetMint.Transit
  alias FleetMint.Transit.Schedule
  alias FleetMint.Fleet

  def index(conn, params) do
    schedules = Transit.list_schedules(status: params["status"])
    render(conn, :index, schedules: schedules)
  end

  def new(conn, _params) do
    changeset = Transit.change_schedule(%Schedule{})
    routes = Fleet.list_routes()
    vehicles = Fleet.list_vehicles(type: "bus", status: "active")
    render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles)
  end

  def create(conn, %{"schedule" => params}) do
    case Transit.create_schedule(params) do
      {:ok, schedule} ->
        conn |> put_flash(:info, "Schedule created.") |> redirect(to: ~p"/schedules/#{schedule}")
      {:error, changeset} ->
        routes = Fleet.list_routes()
        vehicles = Fleet.list_vehicles(type: "bus", status: "active")
        render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles)
    end
  end

  def show(conn, %{"id" => id}) do
    schedule = Transit.get_schedule!(id)
    render(conn, :show, schedule: schedule)
  end

  def edit(conn, %{"id" => id}) do
    schedule = Transit.get_schedule!(id)
    changeset = Transit.change_schedule(schedule)
    routes = Fleet.list_routes()
    vehicles = Fleet.list_vehicles(type: "bus", status: "active")
    render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles)
  end

  def update(conn, %{"id" => id, "schedule" => params}) do
    schedule = Transit.get_schedule!(id)
    case Transit.update_schedule(schedule, params) do
      {:ok, schedule} ->
        conn |> put_flash(:info, "Schedule updated.") |> redirect(to: ~p"/schedules/#{schedule}")
      {:error, changeset} ->
        routes = Fleet.list_routes()
        vehicles = Fleet.list_vehicles(type: "bus", status: "active")
        render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles)
    end
  end

  def delete(conn, %{"id" => id}) do
    schedule = Transit.get_schedule!(id)
    {:ok, _} = Transit.delete_schedule(schedule)
    conn |> put_flash(:info, "Schedule deleted.") |> redirect(to: ~p"/schedules")
  end
end
