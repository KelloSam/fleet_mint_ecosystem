defmodule FleetMintWeb.MinibusTripController do
  use FleetMintWeb, :controller

  alias FleetMint.Transit
  alias FleetMint.Transit.MinibusTrip
  alias FleetMint.Transport.Fleet
  alias FleetMint.Operations

  def index(conn, _params) do
    trips = Transit.list_minibus_trips()
    render(conn, :index, trips: trips)
  end

  def new(conn, _params) do
    changeset = Transit.change_minibus_trip(%MinibusTrip{})
    render(conn, :new,
      changeset: changeset,
      buses: Fleet.list_buses(),
      routes: Fleet.list_routes(),
      drivers: Operations.list_drivers()
    )
  end

  def create(conn, %{"minibus_trip" => params}) do
    case Transit.create_minibus_trip(params) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip recorded.") |> redirect(to: ~p"/minibus_trips/#{trip}")
      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          buses: Fleet.list_buses(),
          routes: Fleet.list_routes(),
          drivers: Operations.list_drivers()
        )
    end
  end

  def show(conn, %{"id" => id}) do
    trip = Transit.get_minibus_trip!(id)
    render(conn, :show, trip: trip)
  end

  def edit(conn, %{"id" => id}) do
    trip = Transit.get_minibus_trip!(id)
    changeset = Transit.change_minibus_trip(trip)
    render(conn, :edit,
      trip: trip,
      changeset: changeset,
      buses: Fleet.list_buses(),
      routes: Fleet.list_routes(),
      drivers: Operations.list_drivers()
    )
  end

  def update(conn, %{"id" => id, "minibus_trip" => params}) do
    trip = Transit.get_minibus_trip!(id)
    case Transit.update_minibus_trip(trip, params) do
      {:ok, trip} ->
        conn |> put_flash(:info, "Trip updated.") |> redirect(to: ~p"/minibus_trips/#{trip}")
      {:error, changeset} ->
        render(conn, :edit,
          trip: trip,
          changeset: changeset,
          buses: Fleet.list_buses(),
          routes: Fleet.list_routes(),
          drivers: Operations.list_drivers()
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    trip = Transit.get_minibus_trip!(id)
    {:ok, _} = Transit.delete_minibus_trip(trip)
    conn |> put_flash(:info, "Trip deleted.") |> redirect(to: ~p"/minibus_trips")
  end
end
