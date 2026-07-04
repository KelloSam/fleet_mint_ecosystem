defmodule FleetMint.Reporting.PdfGenerator do
  @moduledoc "Generates PDF reports by rendering EEx HTML templates through Chrome headless."

  @templates_dir Path.join(:code.priv_dir(:fleet_mint), "templates/pdf")

  @pdf_opts [
    print_to_pdf: %{
      paperWidth: 8.27,
      paperHeight: 11.69,
      printBackground: true,
      marginTop: 0.0,
      marginBottom: 0.0,
      marginLeft: 0.0,
      marginRight: 0.0
    }
  ]

  @a5_opts [
    print_to_pdf: %{
      paperWidth: 5.83,
      paperHeight: 8.27,
      printBackground: true,
      marginTop: 0.0,
      marginBottom: 0.0,
      marginLeft: 0.0,
      marginRight: 0.0
    }
  ]

  def daily_report(date, reports) do
    html = render("daily_report.html.eex",
      date: date,
      reports: reports,
      generated_at: DateTime.utc_now() |> DateTime.to_naive()
    )
    to_pdf(html, @pdf_opts)
  end

  def weekly_report(report) do
    html = render("weekly_report.html.eex",
      report: report,
      generated_at: DateTime.utc_now() |> DateTime.to_naive()
    )
    to_pdf(html, @pdf_opts)
  end

  def cashing_receipt(cr) do
    html = render("cashing_receipt.html.eex",
      cr: cr,
      generated_at: DateTime.utc_now() |> DateTime.to_naive()
    )
    to_pdf(html, @a5_opts)
  end

  def expenditure_report(start_date, end_date, data) do
    html = render("expenditure_report.html.eex",
      start_date: start_date,
      end_date: end_date,
      data: data,
      generated_at: DateTime.utc_now() |> DateTime.to_naive()
    )
    to_pdf(html, @pdf_opts)
  end

  defp render(template, bindings) do
    path = Path.join(@templates_dir, template)
    EEx.eval_file(path, bindings)
  end

  defp to_pdf(html, opts) do
    case ChromicPDF.print_to_pdf({:html, html}, opts) do
      {:ok, blob} -> {:ok, Base.decode64!(blob, ignore: :whitespace)}
      {:error, reason} -> {:error, reason}
    end
  end
end
