defmodule FleetMintWeb.ScheduleController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Trips.Schedule
  alias FleetMint.Transport.Boarding
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Routes
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    schedules = Trips.list_schedules(status: params["status"], operator_id: conn.assigns.operator_scope)
    render(conn, :index, schedules: schedules)
  end

  def new(conn, _params) do
    changeset = Trips.change_schedule(%Schedule{})
    routes = Routes.list_routes()
    vehicles = Fleet.list_vehicles(type: "bus", status: "active")
    operators = Fleet.list_operators()
    render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
  end

  def create(conn, %{"schedule" => params}) do
    params = force_operator_scope(params, conn.assigns.operator_scope)

    case Trips.create_schedule(params) do
      {:ok, schedule} ->
        conn |> put_flash(:info, "Schedule created.") |> redirect(to: ~p"/schedules/#{schedule}")
      {:error, changeset} ->
        routes = Routes.list_routes()
        vehicles = Fleet.list_vehicles(type: "bus", status: "active")
        operators = Fleet.list_operators()
        render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
    end
  end

  def show(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)

    with_operator_access(conn, schedule.operator_id, ~p"/schedules", fn conn ->
      checkpoints = Boarding.list_checkpoints(schedule.id, Date.utc_today())
      render(conn, :show, schedule: schedule, checkpoints: checkpoints)
    end)
  end

  def post_checkpoint(conn, %{"id" => id} = params) do
    schedule = Trips.get_schedule!(id)

    with_operator_access(conn, schedule.operator_id, ~p"/schedules", fn conn ->
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
    end)
  end

  def edit(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)

    with_operator_access(conn, schedule.operator_id, ~p"/schedules", fn conn ->
      changeset = Trips.change_schedule(schedule)
      routes = Routes.list_routes()
      vehicles = Fleet.list_vehicles(type: "bus", status: "active")
      operators = Fleet.list_operators()
      render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
    end)
  end

  def update(conn, %{"id" => id, "schedule" => params}) do
    schedule = Trips.get_schedule!(id)

    with_operator_access(conn, schedule.operator_id, ~p"/schedules", fn conn ->
      params = force_operator_scope(params, conn.assigns.operator_scope)

      case Trips.update_schedule(schedule, params) do
        {:ok, schedule} ->
          conn |> put_flash(:info, "Schedule updated.") |> redirect(to: ~p"/schedules/#{schedule}")
        {:error, changeset} ->
          routes = Routes.list_routes()
          vehicles = Fleet.list_vehicles(type: "bus", status: "active")
          operators = Fleet.list_operators()
          render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)

    with_operator_access(conn, schedule.operator_id, ~p"/schedules", fn conn ->
      {:ok, _} = Trips.delete_schedule(schedule)
      conn |> put_flash(:info, "Schedule deleted.") |> redirect(to: ~p"/schedules")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  # Tenant staff cannot pick another operator's id via a hidden/tampered
  # form field — their own operator_id always wins over whatever was
  # submitted. Platform-level staff (:all scope) submit their own choice.
  defp force_operator_scope(params, :all), do: params
  defp force_operator_scope(params, operator_id), do: Map.put(params, "operator_id", operator_id)

  defp with_operator_access(conn, operator_id, fallback_path, fun) do
    if Authorization.can_access_operator?(conn.assigns.current_user, operator_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That schedule belongs to a different operator.")
      |> redirect(to: fallback_path)
    end
  end
end
