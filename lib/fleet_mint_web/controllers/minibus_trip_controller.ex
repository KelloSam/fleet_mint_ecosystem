defmodule FleetMintWeb.MinibusTripController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Trips.MinibusTrip
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Routes
  alias FleetMint.HR

  def index(conn, _params) do
    trips = Trips.list_minibus_trips()
    render(conn, :index, trips: trips)
  end

  def new(conn, _params) do
    changeset = Trips.change_minibus_trip(%MinibusTrip{})
    render(conn, :new,
      changeset: changeset,
      buses: Fleet.list_buses(),
      routes: Routes.list_routes(),
      drivers: HR.list_drivers()
    )
  end

  def create(conn, %{"minibus_trip" => params}) do
    case Trips.create_minibus_trip(params) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip recorded.") |> redirect(to: ~p"/minibus_trips/#{trip}")
      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          buses: Fleet.list_buses(),
          routes: Routes.list_routes(),
          drivers: HR.list_drivers()
        )
    end
  end

  def show(conn, %{"id" => id}) do
    trip = Trips.get_minibus_trip!(id)
    render(conn, :show, trip: trip)
  end

  def edit(conn, %{"id" => id}) do
    trip = Trips.get_minibus_trip!(id)
    changeset = Trips.change_minibus_trip(trip)
    render(conn, :edit,
      trip: trip,
      changeset: changeset,
      buses: Fleet.list_buses(),
      routes: Routes.list_routes(),
      drivers: HR.list_drivers()
    )
  end

  def update(conn, %{"id" => id, "minibus_trip" => params}) do
    trip = Trips.get_minibus_trip!(id)
    case Trips.update_minibus_trip(trip, params) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip updated.") |> redirect(to: ~p"/minibus_trips/#{trip}")
      {:error, changeset} ->
        render(conn, :edit,
          trip: trip,
          changeset: changeset,
          buses: Fleet.list_buses(),
          routes: Routes.list_routes(),
          drivers: HR.list_drivers()
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    trip = Trips.get_minibus_trip!(id)
    {:ok, _} = Trips.delete_minibus_trip(trip)
    conn |> put_flash(:info, "Trip deleted.") |> redirect(to: ~p"/minibus_trips")
  end
end
