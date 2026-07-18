defmodule FleetMintWeb.DriverController do
  use FleetMintWeb, :controller

  alias FleetMint.HR
  alias FleetMint.HR.Driver
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    drivers = HR.list_drivers(organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, drivers: drivers)
  end

  def new(conn, _params) do
    changeset = HR.change_driver(%Driver{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"driver" => params}) do
    params = force_organisation_scope(params, conn.assigns.organisation_scope)

    case HR.create_driver(params) do
      {:ok, driver} ->
        conn |> put_flash(:info, "Driver created.") |> redirect(to: ~p"/drivers/#{driver}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    driver = HR.get_driver!(id)

    with_organisation_access(conn, driver.organisation_id, ~p"/drivers", fn conn ->
      render(conn, :show, driver: driver)
    end)
  end

  def edit(conn, %{"id" => id}) do
    driver = HR.get_driver!(id)

    with_organisation_access(conn, driver.organisation_id, ~p"/drivers", fn conn ->
      changeset = HR.change_driver(driver)
      render(conn, :edit, driver: driver, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "driver" => params}) do
    driver = HR.get_driver!(id)

    with_organisation_access(conn, driver.organisation_id, ~p"/drivers", fn conn ->
      case HR.update_driver(driver, params) do
        {:ok, driver} ->
          conn |> put_flash(:info, "Driver updated.") |> redirect(to: ~p"/drivers/#{driver}")
        {:error, changeset} ->
          render(conn, :edit, driver: driver, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    driver = HR.get_driver!(id)

    with_organisation_access(conn, driver.organisation_id, ~p"/drivers", fn conn ->
      {:ok, _} = HR.delete_driver(driver)
      conn |> put_flash(:info, "Driver archived.") |> redirect(to: ~p"/drivers")
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
      |> put_flash(:error, "That driver belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
