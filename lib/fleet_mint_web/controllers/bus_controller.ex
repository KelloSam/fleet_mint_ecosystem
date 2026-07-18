defmodule FleetMintWeb.BusController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Fleet.Bus
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    status = Map.get(params, "status")
    scope = conn.assigns.organisation_scope

    buses =
      if status && status != "",
        do: Fleet.list_buses_by_status(status, organisation_id: scope),
        else: Fleet.list_buses(organisation_id: scope)

    render(conn, :index, buses: buses, filter_status: status || "")
  end

  def new(conn, _params) do
    changeset = Fleet.change_bus(%Bus{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"bus" => bus_params}) do
    bus_params = force_organisation_scope(bus_params, conn.assigns.organisation_scope)

    case Fleet.create_bus(bus_params) do
      {:ok, bus} ->
        conn
        |> put_flash(:info, "Bus #{bus.registration_number} added successfully.")
        |> redirect(to: ~p"/buses/#{bus}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    bus = Fleet.get_bus!(id)

    with_organisation_access(conn, bus.organisation_id, ~p"/buses", fn conn ->
      render(conn, :show, bus: bus)
    end)
  end

  def edit(conn, %{"id" => id}) do
    bus = Fleet.get_bus!(id)

    with_organisation_access(conn, bus.organisation_id, ~p"/buses", fn conn ->
      changeset = Fleet.change_bus(bus)
      render(conn, :edit, bus: bus, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "bus" => bus_params}) do
    bus = Fleet.get_bus!(id)

    with_organisation_access(conn, bus.organisation_id, ~p"/buses", fn conn ->
      case Fleet.update_bus(bus, bus_params) do
        {:ok, bus} ->
          conn
          |> put_flash(:info, "Bus #{bus.registration_number} updated successfully.")
          |> redirect(to: ~p"/buses/#{bus}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, bus: bus, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    bus = Fleet.get_bus!(id)

    with_organisation_access(conn, bus.organisation_id, ~p"/buses", fn conn ->
      {:ok, _bus} = Fleet.delete_bus(bus)

      conn
      |> put_flash(:info, "Bus #{bus.registration_number} removed.")
      |> redirect(to: ~p"/buses")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp force_organisation_scope(params, :all), do: params
  defp force_organisation_scope(params, organisation_id), do: Map.put(params, "organisation_id", organisation_id)

  defp with_organisation_access(conn, organisation_id, fallback_path, fun) do
    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That bus belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
