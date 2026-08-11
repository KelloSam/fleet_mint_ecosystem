defmodule FleetMintWeb.MinibusTripController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Trips.MinibusTrip
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Routes
  alias FleetMint.HR
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    trips = Trips.list_minibus_trips(organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, trips: trips)
  end

  def new(conn, _params) do
    changeset = Trips.change_minibus_trip(%MinibusTrip{})

    render(conn, :new,
      changeset: changeset,
      buses: allowed_buses(conn),
      routes: Routes.list_routes(),
      drivers: allowed_drivers(conn)
    )
  end

  def create(conn, %{"minibus_trip" => params}) do
    buses = allowed_buses(conn)

    if bus_allowed?(buses, params["bus_id"]) do
      case Trips.create_minibus_trip(params) do
        {:ok, trip} ->
          conn |> put_flash(:info, "Trip recorded.") |> redirect(to: ~p"/minibus_trips/#{trip}")

        {:error, changeset} ->
          render(conn, :new,
            changeset: changeset,
            buses: buses,
            routes: Routes.list_routes(),
            drivers: allowed_drivers(conn)
          )
      end
    else
      changeset = Trips.change_minibus_trip(%MinibusTrip{})

      conn
      |> put_flash(:error, "That bus is not available to you.")
      |> render(:new,
        changeset: changeset,
        buses: buses,
        routes: Routes.list_routes(),
        drivers: allowed_drivers(conn)
      )
    end
  end

  def show(conn, %{"id" => id}) do
    trip = Trips.get_minibus_trip!(id)

    with_organisation_access(conn, trip.bus, ~p"/minibus_trips", fn conn ->
      render(conn, :show, trip: trip)
    end)
  end

  def edit(conn, %{"id" => id}) do
    trip = Trips.get_minibus_trip!(id)

    with_organisation_access(conn, trip.bus, ~p"/minibus_trips", fn conn ->
      changeset = Trips.change_minibus_trip(trip)

      render(conn, :edit,
        trip: trip,
        changeset: changeset,
        buses: allowed_buses(conn),
        routes: Routes.list_routes(),
        drivers: allowed_drivers(conn)
      )
    end)
  end

  def update(conn, %{"id" => id, "minibus_trip" => params}) do
    trip = Trips.get_minibus_trip!(id)

    with_organisation_access(conn, trip.bus, ~p"/minibus_trips", fn conn ->
      case Trips.update_minibus_trip(trip, params) do
        {:ok, trip} ->
          conn |> put_flash(:info, "Trip updated.") |> redirect(to: ~p"/minibus_trips/#{trip}")

        {:error, changeset} ->
          render(conn, :edit,
            trip: trip,
            changeset: changeset,
            buses: allowed_buses(conn),
            routes: Routes.list_routes(),
            drivers: allowed_drivers(conn)
          )
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    trip = Trips.get_minibus_trip!(id)

    with_organisation_access(conn, trip.bus, ~p"/minibus_trips", fn conn ->
      {:ok, _} = Trips.delete_minibus_trip(trip)
      conn |> put_flash(:info, "Trip deleted.") |> redirect(to: ~p"/minibus_trips")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp allowed_buses(conn),
    do: Fleet.list_buses(organisation_id: conn.assigns.organisation_scope)

  defp allowed_drivers(conn),
    do: HR.list_drivers(organisation_id: conn.assigns.organisation_scope)

  defp bus_allowed?(buses, bus_id) do
    bus_id = to_string(bus_id)
    Enum.any?(buses, &(to_string(&1.id) == bus_id))
  end

  defp with_organisation_access(conn, bus, fallback_path, fun) do
    organisation_id = bus && bus.organisation_id

    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That trip belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
