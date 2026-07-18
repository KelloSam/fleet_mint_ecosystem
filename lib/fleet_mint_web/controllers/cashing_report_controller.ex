defmodule FleetMintWeb.CashingReportController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.CashingReport
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Trips
  alias FleetMint.Identity.Authorization

  plug :require_admin_or_manager when action in [:edit, :update, :delete, :edit_trip_match, :match_trip]

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

  # ── Trip matching (Phase 2b reconciliation) ────────────────────────────

  @doc """
  The work queue: cashing_reports not yet attributed to a Trip
  (`pending`/`ambiguous`/`unmappable`), scoped to the caller's organisation.
  """
  def unmatched(conn, _params) do
    cashing_reports = Finance.list_unreconciled_cashing_reports(organisation_id: conn.assigns.organisation_scope)
    render(conn, :unmatched, cashing_reports: cashing_reports)
  end

  def edit_trip_match(conn, %{"id" => id}) do
    cashing_report = Finance.get_cashing_report!(id)

    with_organisation_access(conn, cashing_report.bus, ~p"/cashing_reports/unmatched", fn conn ->
      candidate_trips =
        if cashing_report.bus do
          Trips.list_trips_near_date(cashing_report.bus.organisation_id, cashing_report.report_date)
        else
          []
        end

      render(conn, :trip_match, cashing_report: cashing_report, candidate_trips: candidate_trips)
    end)
  end

  def match_trip(conn, %{"id" => id, "trip_id" => trip_id} = params) do
    cashing_report = Finance.get_cashing_report!(id)

    with_organisation_access(conn, cashing_report.bus, ~p"/cashing_reports/unmatched", fn conn ->
      trip = Trips.get_trip!(trip_id)
      match_opts = allocated_amount_opts(params["allocated_amount"])

      case Finance.match_cashing_report_to_trip(cashing_report, trip, conn.assigns.current_user, match_opts) do
        {:ok, _matched} ->
          conn
          |> put_flash(:info, "Cashing report matched to trip.")
          |> redirect(to: ~p"/cashing_reports/unmatched")

        {:error, :organisation_mismatch} ->
          conn
          |> put_flash(:error, "That trip belongs to a different organisation.")
          |> redirect(to: ~p"/cashing_reports/#{cashing_report}/trip_match")

        {:error, :no_bus_on_report} ->
          conn
          |> put_flash(:error, "This report has no bus recorded, so it can't be matched to a trip.")
          |> redirect(to: ~p"/cashing_reports/unmatched")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Could not record that match — check the amount and try again.")
          |> redirect(to: ~p"/cashing_reports/#{cashing_report}/trip_match")
      end
    end)
  end

  defp allocated_amount_opts(nil), do: []
  defp allocated_amount_opts(""), do: []
  defp allocated_amount_opts(amount), do: [allocated_amount: amount]

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
