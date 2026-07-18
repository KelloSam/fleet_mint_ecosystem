defmodule FleetMintWeb.FreightTripController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Trip
  alias FleetMint.Transport.Fleet
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    trips = Cargo.list_trips(status: params["status"], organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, trips: trips)
  end

  def new(conn, _params) do
    changeset = Cargo.change_trip(%Trip{})
    vehicles = allowed_vehicles(conn)
    drivers = FleetMint.HR.list_drivers(organisation_id: conn.assigns.organisation_scope)
    render(conn, :new, changeset: changeset, vehicles: vehicles, drivers: drivers)
  end

  def create(conn, %{"trip" => params}) do
    user_id = conn.assigns[:current_user].id
    vehicles = allowed_vehicles(conn)

    if vehicle_allowed?(vehicles, params["vehicle_id"]) do
      case Cargo.create_trip(params, user_id) do
        {:ok, trip} ->
          conn |> put_flash(:info, "Trip #{trip.trip_reference} scheduled.") |> redirect(to: ~p"/freight/trips/#{trip}")
        {:error, changeset} ->
          drivers = FleetMint.HR.list_drivers(organisation_id: conn.assigns.organisation_scope)
          render(conn, :new, changeset: changeset, vehicles: vehicles, drivers: drivers)
      end
    else
      changeset = Cargo.change_trip(%Trip{})
      drivers = FleetMint.HR.list_drivers(organisation_id: conn.assigns.organisation_scope)
      conn
      |> put_flash(:error, "That vehicle is not available to you.")
      |> render(:new, changeset: changeset, vehicles: vehicles, drivers: drivers)
    end
  end

  def show(conn, %{"id" => id}) do
    trip = Cargo.get_trip!(id)

    with_organisation_access(conn, trip.vehicle, ~p"/freight/trips", fn conn ->
      render(conn, :show, trip: trip)
    end)
  end

  def edit(conn, %{"id" => id}) do
    trip = Cargo.get_trip!(id)

    with_organisation_access(conn, trip.vehicle, ~p"/freight/trips", fn conn ->
      changeset = Cargo.change_trip(trip)
      vehicles = allowed_vehicles(conn)
      drivers = FleetMint.HR.list_drivers(organisation_id: conn.assigns.organisation_scope)
      render(conn, :edit, trip: trip, changeset: changeset, vehicles: vehicles, drivers: drivers)
    end)
  end

  def update(conn, %{"id" => id, "trip" => params}) do
    trip = Cargo.get_trip!(id)

    with_organisation_access(conn, trip.vehicle, ~p"/freight/trips", fn conn ->
      case Cargo.update_trip(trip, params) do
        {:ok, trip} ->
          conn |> put_flash(:info, "Trip updated.") |> redirect(to: ~p"/freight/trips/#{trip}")
        {:error, changeset} ->
          vehicles = allowed_vehicles(conn)
          drivers = FleetMint.HR.list_drivers(organisation_id: conn.assigns.organisation_scope)
          render(conn, :edit, trip: trip, changeset: changeset, vehicles: vehicles, drivers: drivers)
      end
    end)
  end

  def update_status(conn, %{"freight_trip_id" => id, "status" => status}) do
    trip = Cargo.get_trip!(id)

    with_organisation_access(conn, trip.vehicle, ~p"/freight/trips", fn conn ->
      case Cargo.update_trip_status(trip, status) do
        {:ok, trip} ->
          conn |> put_flash(:info, "Trip status updated to #{status}.") |> redirect(to: ~p"/freight/trips/#{trip}")
        {:error, _} ->
          conn |> put_flash(:error, "Could not update status.") |> redirect(to: ~p"/freight/trips/#{trip}")
      end
    end)
  end

  def add_milestone(conn, %{"freight_trip_id" => trip_id, "milestone" => params}) do
    trip = Cargo.get_trip!(trip_id)

    with_organisation_access(conn, trip.vehicle, ~p"/freight/trips", fn conn ->
      case Cargo.add_milestone(trip, params) do
        {:ok, _milestone} ->
          conn |> put_flash(:info, "Milestone recorded.") |> redirect(to: ~p"/freight/trips/#{trip}")
        {:error, _} ->
          conn |> put_flash(:error, "Could not record milestone.") |> redirect(to: ~p"/freight/trips/#{trip}")
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    trip = Cargo.get_trip!(id)

    with_organisation_access(conn, trip.vehicle, ~p"/freight/trips", fn conn ->
      {:ok, _} = Cargo.delete_trip(trip)
      conn |> put_flash(:info, "Trip deleted.") |> redirect(to: ~p"/freight/trips")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp allowed_vehicles(conn), do: Fleet.list_trucks(organisation_id: conn.assigns.organisation_scope)

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
      |> put_flash(:error, "That trip belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
