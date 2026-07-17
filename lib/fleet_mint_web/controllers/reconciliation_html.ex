defmodule FleetMintWeb.ReconciliationHTML do
  use FleetMintWeb, :html
  embed_templates "reconciliation_html/*"

  def variance_badge(true), do: "text-green-700 bg-green-50 border-green-200"
  def variance_badge(false), do: "text-red-700 bg-red-50 border-red-200"

  def status_badge("paid"), do: "text-green-700 bg-green-50"
  def status_badge("issued"), do: "text-blue-700 bg-blue-50"
  def status_badge("overdue"), do: "text-red-700 bg-red-50"
  def status_badge("draft"), do: "text-gray-600 bg-gray-100"
  def status_badge("cancelled"), do: "text-gray-400 bg-gray-50"
  def status_badge(_), do: "text-gray-600 bg-gray-100"

  def cashier_total(rows) do
    Enum.reduce(rows, Decimal.new(0), fn row, acc -> Decimal.add(acc, row.total) end)
  end
end
