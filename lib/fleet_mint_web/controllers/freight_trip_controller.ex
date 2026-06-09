defmodule FleetMintWeb.FreightTripController do
  use FleetMintWeb, :controller
  alias FleetMint.Freight
  alias FleetMint.Freight.Trip
  alias FleetMint.Fleet

  def index(conn, params) do
    trips = Freight.list_trips(status: params["status"])
    render(conn, :index, trips: trips)
  end

  def new(conn, _params) do
    changeset = Freight.change_trip(%Trip{})
    vehicles = Fleet.list_trucks()
    drivers = FleetMint.Accounts.list_users_by_role("operator")
    render(conn, :new, changeset: changeset, vehicles: vehicles, drivers: drivers)
  end

  def create(conn, %{"trip" => params}) do
    user_id = conn.assigns[:current_user].id
    case Freight.create_trip(params, user_id) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip #{trip.trip_reference} scheduled.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, changeset} ->
        vehicles = Fleet.list_trucks()
        drivers = FleetMint.Accounts.list_users_by_role("operator")
        render(conn, :new, changeset: changeset, vehicles: vehicles, drivers: drivers)
    end
  end

  def show(conn, %{"id" => id}) do
    trip = Freight.get_trip!(id)
    render(conn, :show, trip: trip)
  end

  def edit(conn, %{"id" => id}) do
    trip = Freight.get_trip!(id)
    changeset = Freight.change_trip(trip)
    vehicles = Fleet.list_trucks()
    drivers = FleetMint.Accounts.list_users_by_role("operator")
    render(conn, :edit, trip: trip, changeset: changeset, vehicles: vehicles, drivers: drivers)
  end

  def update(conn, %{"id" => id, "trip" => params}) do
    trip = Freight.get_trip!(id)
    case Freight.update_trip(trip, params) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip updated.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, changeset} ->
        vehicles = Fleet.list_trucks()
        drivers = FleetMint.Accounts.list_users_by_role("operator")
        render(conn, :edit, trip: trip, changeset: changeset, vehicles: vehicles, drivers: drivers)
    end
  end

  def update_status(conn, %{"freight_trip_id" => id, "status" => status}) do
    trip = Freight.get_trip!(id)
    case Freight.update_trip_status(trip, status) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip status updated to #{status}.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, _} ->
        conn |> put_flash(:error, "Could not update status.") |> redirect(to: ~p"/freight/trips/#{trip}")
    end
  end

  def add_milestone(conn, %{"freight_trip_id" => trip_id, "milestone" => params}) do
    trip = Freight.get_trip!(trip_id)
    case Freight.add_milestone(trip, params) do
      {:ok, _milestone} ->
        conn |> put_flash(:info, "Milestone recorded.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, _} ->
        conn |> put_flash(:error, "Could not record milestone.") |> redirect(to: ~p"/freight/trips/#{trip}")
    end
  end

  def delete(conn, %{"id" => id}) do
    trip = Freight.get_trip!(id)
    {:ok, _} = Freight.delete_trip(trip)
    conn |> put_flash(:info, "Trip deleted.") |> redirect(to: ~p"/freight/trips")
  end
end
