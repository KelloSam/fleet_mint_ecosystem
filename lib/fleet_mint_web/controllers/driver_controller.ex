defmodule FleetMintWeb.DriverController do
  use FleetMintWeb, :controller

  alias FleetMint.HR
  alias FleetMint.HR.Driver

  def index(conn, _params) do
    drivers = HR.list_drivers()
    render(conn, :index, drivers: drivers)
  end

  def new(conn, _params) do
    changeset = HR.change_driver(%Driver{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"driver" => params}) do
    case HR.create_driver(params) do
      {:ok, driver} ->
        conn |> put_flash(:info, "Driver created.") |> redirect(to: ~p"/drivers/#{driver}")
      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    driver = HR.get_driver!(id)
    render(conn, :show, driver: driver)
  end

  def edit(conn, %{"id" => id}) do
    driver = HR.get_driver!(id)
    changeset = HR.change_driver(driver)
    render(conn, :edit, driver: driver, changeset: changeset)
  end

  def update(conn, %{"id" => id, "driver" => params}) do
    driver = HR.get_driver!(id)
    case HR.update_driver(driver, params) do
      {:ok, driver} ->
        conn |> put_flash(:info, "Driver updated.") |> redirect(to: ~p"/drivers/#{driver}")
      {:error, changeset} ->
        render(conn, :edit, driver: driver, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    driver = HR.get_driver!(id)
    {:ok, _} = HR.delete_driver(driver)
    conn |> put_flash(:info, "Driver archived.") |> redirect(to: ~p"/drivers")
  end
end
