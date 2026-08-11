defmodule FleetMintWeb.ReportController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.Report
  alias FleetMint.Identity.Authorization

  def index(conn, _params) do
    reports = Finance.list_weekly_reports()
    render(conn, :index, reports: reports)
  end

  def new(conn, _params) do
    changeset = Finance.change_report(%Report{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"report" => report_params}) do
    case Finance.create_report(report_params) do
      {:ok, report} ->
        conn
        |> put_flash(:info, "Report created successfully.")
        |> redirect(to: ~p"/reports/#{report}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    report = Finance.get_report!(id)
    render(conn, :show, report: report)
  end

  def edit(conn, %{"id" => id}) do
    report = Finance.get_report!(id)

    with_organisation_access(conn, report.id, ~p"/reports", fn conn ->
      changeset = Finance.change_report(report)
      render(conn, :edit, report: report, changeset: changeset)
    end)
  end

  def update(conn, %{"id" => id, "report" => report_params}) do
    report = Finance.get_report!(id)

    with_organisation_access(conn, report.id, ~p"/reports", fn conn ->
      case Finance.update_report(report, report_params) do
        {:ok, report} ->
          conn
          |> put_flash(:info, "Report updated successfully.")
          |> redirect(to: ~p"/reports/#{report}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, report: report, changeset: changeset)
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    report = Finance.get_report!(id)

    with_organisation_access(conn, report.id, ~p"/reports", fn conn ->
      {:ok, _report} = Finance.delete_report(report)

      conn
      |> put_flash(:info, "Report deleted successfully.")
      |> redirect(to: ~p"/reports")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  # A weekly report has no organisation of its own — it's a shared
  # date-range bucket that every tenant's cashing reports get filed
  # under. Mutating/deleting one is only safe if every cashing report
  # currently attached to it belongs to organisations the caller can
  # access (an empty report — nothing attached yet — is always safe).
  defp with_organisation_access(conn, report_id, fallback_path, fun) do
    org_ids = Finance.report_organisation_ids(report_id)
    user = conn.assigns.current_user

    if Enum.all?(org_ids, &Authorization.can_access_organisation?(user, &1)) do
      fun.(conn)
    else
      conn
      |> put_flash(
        :error,
        "That report includes cashing reports from a different organisation."
      )
      |> redirect(to: fallback_path)
    end
  end
end
