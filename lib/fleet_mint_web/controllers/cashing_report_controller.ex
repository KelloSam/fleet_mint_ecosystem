defmodule FleetMintWeb.CashingReportController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Finance.CashingReport

  def index(conn, _params) do
    cashing_reports = Finance.list_cashing_reports()
    render(conn, :index, cashing_reports: cashing_reports)
  end

  def new(conn, _params) do
    changeset = Finance.change_cashing_report(%CashingReport{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"cashing_report" => cashing_report_params}) do
    case Finance.create_cashing_report(cashing_report_params) do
      {:ok, cashing_report} ->
        conn
        |> put_flash(:info, "Cashing report created successfully.")
        |> redirect(to: ~p"/cashing_reports/#{cashing_report}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    cashing_report = Finance.get_cashing_report!(id)
    render(conn, :show, cashing_report: cashing_report)
  end

  def edit(conn, %{"id" => id}) do
    cashing_report = Finance.get_cashing_report!(id)
    changeset = Finance.change_cashing_report(cashing_report)
    render(conn, :edit, cashing_report: cashing_report, changeset: changeset)
  end

  def update(conn, %{"id" => id, "cashing_report" => cashing_report_params}) do
    cashing_report = Finance.get_cashing_report!(id)

    case Finance.update_cashing_report(cashing_report, cashing_report_params) do
      {:ok, cashing_report} ->
        conn
        |> put_flash(:info, "Cashing report updated successfully.")
        |> redirect(to: ~p"/cashing_reports/#{cashing_report}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, cashing_report: cashing_report, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    cashing_report = Finance.get_cashing_report!(id)
    {:ok, _cashing_report} = Finance.delete_cashing_report(cashing_report)

    conn
    |> put_flash(:info, "Cashing report deleted successfully.")
    |> redirect(to: ~p"/cashing_reports")
  end
end
