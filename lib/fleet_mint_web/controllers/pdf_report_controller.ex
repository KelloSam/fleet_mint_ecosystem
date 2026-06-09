defmodule FleetMintWeb.PdfReportController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Reports.PdfGenerator

  # GET /admin/reports — Reports hub page
  def index(conn, params) do
    reports = Finance.list_weekly_reports()
    date = Map.get(params, "date", Date.utc_today() |> Date.to_iso8601())
    from = Map.get(params, "from", Date.beginning_of_week(Date.utc_today()) |> Date.to_iso8601())
    to = Map.get(params, "to", Date.utc_today() |> Date.to_iso8601())
    render(conn, :index, reports: reports, date: date, from: from, to: to)
  end

  # GET /pdf/daily?date=YYYY-MM-DD
  def daily(conn, %{"date" => date_string}) do
    with {:ok, date} <- Date.from_iso8601(date_string) do
      reports = Finance.list_cashing_reports_for_date(date)

      case PdfGenerator.daily_report(date, reports) do
        {:ok, pdf} -> send_pdf(conn, pdf, "daily_report_#{date_string}.pdf")
        {:error, _} -> pdf_error(conn, ~p"/admin/reports")
      end
    else
      _ ->
        conn |> put_flash(:error, "Invalid date.") |> redirect(to: ~p"/admin/reports")
    end
  end

  # GET /pdf/weekly/:id
  def weekly(conn, %{"id" => id}) do
    report = Finance.get_report_with_cashing_details!(id)

    case PdfGenerator.weekly_report(report) do
      {:ok, pdf} ->
        filename = "weekly_report_#{report.start_date}_to_#{report.end_date}.pdf"
        send_pdf(conn, pdf, filename)
      {:error, _} ->
        pdf_error(conn, ~p"/reports/#{id}")
    end
  end

  # GET /pdf/receipt/:id
  def receipt(conn, %{"id" => id}) do
    cr = Finance.get_cashing_report_with_details!(id)

    case PdfGenerator.cashing_receipt(cr) do
      {:ok, pdf} -> send_pdf(conn, pdf, "cashing_receipt_#{id}.pdf")
      {:error, _} -> pdf_error(conn, ~p"/cashing_reports/#{id}")
    end
  end

  # GET /pdf/expenditures?from=YYYY-MM-DD&to=YYYY-MM-DD
  def expenditures(conn, params) do
    start_str = Map.get(params, "from", Date.beginning_of_week(Date.utc_today()) |> Date.to_iso8601())
    end_str = Map.get(params, "to", Date.utc_today() |> Date.to_iso8601())

    with {:ok, start_date} <- Date.from_iso8601(start_str),
         {:ok, end_date} <- Date.from_iso8601(end_str) do
      data = Finance.get_expenditures_report(start_date, end_date)

      case PdfGenerator.expenditure_report(start_date, end_date, data) do
        {:ok, pdf} ->
          send_pdf(conn, pdf, "expenditures_#{start_str}_to_#{end_str}.pdf")
        {:error, _} ->
          pdf_error(conn, ~p"/admin/reports")
      end
    else
      _ ->
        conn |> put_flash(:error, "Invalid date range.") |> redirect(to: ~p"/admin/reports")
    end
  end

  defp send_pdf(conn, pdf_binary, filename) do
    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, pdf_binary)
  end

  defp pdf_error(conn, redirect_to) do
    conn
    |> put_flash(:error, "PDF generation failed. Please try again.")
    |> redirect(to: redirect_to)
  end
end
