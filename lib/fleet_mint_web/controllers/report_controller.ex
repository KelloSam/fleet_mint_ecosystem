defmodule FleetMintWeb.ReportController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.Report

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
    changeset = Finance.change_report(report)
    render(conn, :edit, report: report, changeset: changeset)
  end

  def update(conn, %{"id" => id, "report" => report_params}) do
    report = Finance.get_report!(id)

    case Finance.update_report(report, report_params) do
      {:ok, report} ->
        conn
        |> put_flash(:info, "Report updated successfully.")
        |> redirect(to: ~p"/reports/#{report}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, report: report, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    report = Finance.get_report!(id)
    {:ok, _report} = Finance.delete_report(report)

    conn
    |> put_flash(:info, "Report deleted successfully.")
    |> redirect(to: ~p"/reports")
  end
end
