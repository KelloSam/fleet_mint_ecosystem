defmodule FleetMintWeb.FreightTripController do
  use FleetMintWeb, :controller
  alias FleetMint.Cargo
  alias FleetMint.Cargo.Trip
  alias FleetMint.Transport.Fleet

  def index(conn, params) do
    trips = Cargo.list_trips(status: params["status"])
    render(conn, :index, trips: trips)
  end

  def new(conn, _params) do
    changeset = Cargo.change_trip(%Trip{})
    vehicles = Fleet.list_trucks()
    drivers = FleetMint.Operations.list_drivers()
    render(conn, :new, changeset: changeset, vehicles: vehicles, drivers: drivers)
  end

  def create(conn, %{"trip" => params}) do
    user_id = conn.assigns[:current_user].id
    case Cargo.create_trip(params, user_id) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip #{trip.trip_reference} scheduled.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, changeset} ->
        vehicles = Fleet.list_trucks()
        drivers = FleetMint.Operations.list_drivers()
        render(conn, :new, changeset: changeset, vehicles: vehicles, drivers: drivers)
    end
  end

  def show(conn, %{"id" => id}) do
    trip = Cargo.get_trip!(id)
    render(conn, :show, trip: trip)
  end

  def edit(conn, %{"id" => id}) do
    trip = Cargo.get_trip!(id)
    changeset = Cargo.change_trip(trip)
    vehicles = Fleet.list_trucks()
    drivers = FleetMint.Operations.list_drivers()
    render(conn, :edit, trip: trip, changeset: changeset, vehicles: vehicles, drivers: drivers)
  end

  def update(conn, %{"id" => id, "trip" => params}) do
    trip = Cargo.get_trip!(id)
    case Cargo.update_trip(trip, params) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip updated.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, changeset} ->
        vehicles = Fleet.list_trucks()
        drivers = FleetMint.Operations.list_drivers()
        render(conn, :edit, trip: trip, changeset: changeset, vehicles: vehicles, drivers: drivers)
    end
  end

  def update_status(conn, %{"freight_trip_id" => id, "status" => status}) do
    trip = Cargo.get_trip!(id)
    case Cargo.update_trip_status(trip, status) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip status updated to #{status}.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, _} ->
        conn |> put_flash(:error, "Could not update status.") |> redirect(to: ~p"/freight/trips/#{trip}")
    end
  end

  def add_milestone(conn, %{"freight_trip_id" => trip_id, "milestone" => params}) do
    trip = Cargo.get_trip!(trip_id)
    case Cargo.add_milestone(trip, params) do
      {:ok, _milestone} ->
        conn |> put_flash(:info, "Milestone recorded.") |> redirect(to: ~p"/freight/trips/#{trip}")
      {:error, _} ->
        conn |> put_flash(:error, "Could not record milestone.") |> redirect(to: ~p"/freight/trips/#{trip}")
    end
  end

  def delete(conn, %{"id" => id}) do
    trip = Cargo.get_trip!(id)
    {:ok, _} = Cargo.delete_trip(trip)
    conn |> put_flash(:info, "Trip deleted.") |> redirect(to: ~p"/freight/trips")
  end
end
