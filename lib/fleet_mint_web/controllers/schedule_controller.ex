defmodule FleetMintWeb.ScheduleController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Trips.Schedule
  alias FleetMint.Transport.Boarding
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Routes
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    schedules = Trips.list_schedules(status: params["status"], organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, schedules: schedules)
  end

  def new(conn, _params) do
    changeset = Trips.change_schedule(%Schedule{})
    routes = Routes.list_routes()
    vehicles = Fleet.list_vehicles(type: "bus", status: "active", organisation_id: conn.assigns.organisation_scope)
    operators = Fleet.list_operators()
    render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
  end

  def create(conn, %{"schedule" => params}) do
    params = force_organisation_scope(params, conn.assigns.organisation_scope)

    case Trips.create_schedule(params) do
      {:ok, schedule} ->
        conn |> put_flash(:info, "Schedule created.") |> redirect(to: ~p"/schedules/#{schedule}")
      {:error, changeset} ->
        routes = Routes.list_routes()
        vehicles = Fleet.list_vehicles(type: "bus", status: "active", organisation_id: conn.assigns.organisation_scope)
        operators = Fleet.list_operators()
        render(conn, :new, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
    end
  end

  def show(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)

    with_organisation_access(conn, schedule.operator, ~p"/schedules", fn conn ->
      checkpoints = Boarding.list_checkpoints(schedule.id, Date.utc_today())
      render(conn, :show, schedule: schedule, checkpoints: checkpoints)
    end)
  end

  def post_checkpoint(conn, %{"id" => id} = params) do
    schedule = Trips.get_schedule!(id)

    with_organisation_access(conn, schedule.operator, ~p"/schedules", fn conn ->
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

    with_organisation_access(conn, schedule.operator, ~p"/schedules", fn conn ->
      changeset = Trips.change_schedule(schedule)
      routes = Routes.list_routes()
      vehicles = Fleet.list_vehicles(type: "bus", status: "active", organisation_id: conn.assigns.organisation_scope)
      operators = Fleet.list_operators()
      render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
    end)
  end

  def update(conn, %{"id" => id, "schedule" => params}) do
    schedule = Trips.get_schedule!(id)

    with_organisation_access(conn, schedule.operator, ~p"/schedules", fn conn ->
      params = force_organisation_scope(params, conn.assigns.organisation_scope)

      case Trips.update_schedule(schedule, params) do
        {:ok, schedule} ->
          conn |> put_flash(:info, "Schedule updated.") |> redirect(to: ~p"/schedules/#{schedule}")
        {:error, changeset} ->
          routes = Routes.list_routes()
          vehicles = Fleet.list_vehicles(type: "bus", status: "active", organisation_id: conn.assigns.organisation_scope)
          operators = Fleet.list_operators()
          render(conn, :edit, schedule: schedule, changeset: changeset, routes: routes, vehicles: vehicles, operators: operators)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    schedule = Trips.get_schedule!(id)

    with_organisation_access(conn, schedule.operator, ~p"/schedules", fn conn ->
      {:ok, _} = Trips.delete_schedule(schedule)
      conn |> put_flash(:info, "Schedule deleted.") |> redirect(to: ~p"/schedules")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  # Tenant staff cannot pick another organisation's operator via a
  # hidden/tampered form field — their own organisation's operator always
  # wins over whatever was submitted. Platform-level staff (:all scope)
  # submit their own choice.
  defp force_organisation_scope(params, :all), do: params
  defp force_organisation_scope(params, organisation_id) do
    operator_id =
      case Fleet.get_operator_by_organisation(organisation_id) do
        nil -> nil
        operator -> operator.id
      end

    Map.put(params, "operator_id", operator_id)
  end

  defp with_organisation_access(conn, operator, fallback_path, fun) do
    organisation_id = operator && operator.organisation_id

    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That schedule belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
