defmodule FleetMintWeb.CashingReportController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.CashingReport
  alias FleetMint.Transport.Fleet
  alias FleetMint.Identity.Authorization

  plug :require_admin_or_manager when action in [:edit, :update, :delete]

  def index(conn, _params) do
    cashing_reports = Finance.list_cashing_reports(organisation_id: conn.assigns.organisation_scope)
    render(conn, :index, cashing_reports: cashing_reports)
  end

  def new(conn, _params) do
    changeset = Finance.change_cashing_report(%CashingReport{report_date: Date.utc_today()})
    render(conn, :new, changeset: changeset, buses: allowed_buses(conn))
  end

  def create(conn, %{"cashing_report" => cashing_report_params}) do
    buses = allowed_buses(conn)

    if bus_allowed?(buses, cashing_report_params["bus_id"]) do
      case Finance.create_cashing_report(cashing_report_params) do
        {:ok, cashing_report} ->
          conn
          |> put_flash(:info, "Cashing report created successfully.")
          |> redirect(to: ~p"/cashing_reports/#{cashing_report}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :new, changeset: changeset, buses: buses)
      end
    else
      changeset = Finance.change_cashing_report(%CashingReport{report_date: Date.utc_today()})
      conn
      |> put_flash(:error, "That bus is not available to you.")
      |> render(:new, changeset: changeset, buses: buses)
    end
  end

  def show(conn, %{"id" => id}) do
    cashing_report = Finance.get_cashing_report!(id)

    with_organisation_access(conn, cashing_report.bus, ~p"/cashing_reports", fn conn ->
      render(conn, :show, cashing_report: cashing_report)
    end)
  end

  def edit(conn, %{"id" => id}) do
    cashing_report = Finance.get_cashing_report!(id)

    with_organisation_access(conn, cashing_report.bus, ~p"/cashing_reports", fn conn ->
      changeset = Finance.change_cashing_report(cashing_report)
      render(conn, :edit, cashing_report: cashing_report, changeset: changeset, buses: allowed_buses(conn))
    end)
  end

  def update(conn, %{"id" => id, "cashing_report" => cashing_report_params}) do
    cashing_report = Finance.get_cashing_report!(id)

    with_organisation_access(conn, cashing_report.bus, ~p"/cashing_reports", fn conn ->
      case Finance.update_cashing_report(cashing_report, cashing_report_params) do
        {:ok, cashing_report} ->
          conn
          |> put_flash(:info, "Cashing report updated successfully.")
          |> redirect(to: ~p"/cashing_reports/#{cashing_report}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, cashing_report: cashing_report, changeset: changeset, buses: allowed_buses(conn))
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    cashing_report = Finance.get_cashing_report!(id)

    with_organisation_access(conn, cashing_report.bus, ~p"/cashing_reports", fn conn ->
      {:ok, _cashing_report} = Finance.delete_cashing_report(cashing_report)

      conn
      |> put_flash(:info, "Cashing report deleted successfully.")
      |> redirect(to: ~p"/cashing_reports")
    end)
  end

  defp require_admin_or_manager(conn, _opts) do
    if FleetMint.Identity.Authorization.authorized?(conn.assigns.current_user, ["admin", "manager"]) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorised to perform this action.")
      |> redirect(to: ~p"/cashing_reports")
      |> halt()
    end
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp allowed_buses(conn), do: Fleet.list_buses(organisation_id: conn.assigns.organisation_scope)

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
      |> put_flash(:error, "That cashing report belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
