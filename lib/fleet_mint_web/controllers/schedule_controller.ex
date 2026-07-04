defmodule FleetMintWeb.ScheduleController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Trips.Schedule
  alias FleetMint.Transport.Boarding
  alias FleetMint.Transport.Fleet

  def index(conn, params) do
    schedules = Trips.list_schedules(status: params["status"])
    render(conn, :index, schedules: schedules)
  end

  def new(conn, _params) do
    changeset = Trips.change_schedule(%Schedule{})
    routes = Fleet.list_routes()
    vehicles = Fleet.list_vehicles(type: "bus", status: "active")
    operators = Fleet.list_operators()
    render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
  end

  def create(conn, %{"schedule" => params}) do
    case Trips.create_schedule(params) do
      {:ok, schedule} ->
        conn |> put_flash(:info, "Schedule created.") |> redirect(to: ~p"/schedules/#{schedule}")
      {:error, changeset} ->
        routes = Fleet.list_routes()
        vehicles = Fleet.list_vehicles(type: "bus", status: "active")
        operators = Fleet.list_operators()
        render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
    end
  end

  def show(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)
    checkpoints = Boarding.list_checkpoints(schedule.id, Date.utc_today())
    render(conn, :show, schedule: schedule, checkpoints: checkpoints)
  end

  def post_checkpoint(conn, %{"id" => id} = params) do
    schedule = Trips.get_schedule!(id)
    attrs = %{
      "schedule_id" => schedule.id,
      "travel_date" => params["travel_date"] || to_string(Date.utc_today()),
      "location" => params["location"],
      "notes" => params["notes"],
      "reported_by_id" => conn.assigns.current_user.id
    }
    case Boarding.post_checkpoint(attrs) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Location updated: #{params["location"]}")
        |> redirect(to: ~p"/schedules/#{schedule}")
      {:error, _} ->
        conn
        |> put_flash(:error, "Could not post update. Check the location field.")
        |> redirect(to: ~p"/schedules/#{schedule}")
    end
  end

  def edit(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)
    changeset = Trips.change_schedule(schedule)
    routes = Fleet.list_routes()
    vehicles = Fleet.list_vehicles(type: "bus", status: "active")
    operators = Fleet.list_operators()
    render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
  end

  def update(conn, %{"id" => id, "schedule" => params}) do
    schedule = Trips.get_schedule!(id)
    case Trips.update_schedule(schedule, params) do
      {:ok, schedule} ->
        conn |> put_flash(:info, "Schedule updated.") |> redirect(to: ~p"/schedules/#{schedule}")
      {:error, changeset} ->
        routes = Fleet.list_routes()
        vehicles = Fleet.list_vehicles(type: "bus", status: "active")
        operators = Fleet.list_operators()
        render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
    end
  end

  def delete(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)
    {:ok, _} = Trips.delete_schedule(schedule)
    conn |> put_flash(:info, "Schedule deleted.") |> redirect(to: ~p"/schedules")
  end
end
