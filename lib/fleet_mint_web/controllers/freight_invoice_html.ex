defmodule FleetMintWeb.FreightInvoiceHTML do
  use FleetMintWeb, :html

  embed_templates "freight_invoice_html/*"

  def status_badge(assigns) do
    color =
      case assigns.status do
        "draft" -> "bg-gray-100 text-gray-700"
        "issued" -> "bg-blue-100 text-blue-800"
        "paid" -> "bg-green-100 text-green-800"
        "overdue" -> "bg-red-100 text-red-800"
        "cancelled" -> "bg-gray-100 text-gray-500"
        _ -> "bg-gray-100 text-gray-600"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{@color}"}>
      <%= String.capitalize(@status || "unknown") %>
    </span>
    """
  end

  def status_options,
    do: [
      {"Draft", "draft"},
      {"Issued", "issued"},
      {"Paid", "paid"},
      {"Overdue", "overdue"},
      {"Cancelled", "cancelled"}
    ]

  def client_options(clients), do: Enum.map(clients, &{&1.company_name, &1.id})
  def trip_options(trips), do: Enum.map(trips, &{"#{&1.trip_reference} (#{&1.origin} → #{&1.destination})", &1.id})

  def format_money(nil), do: "—"
  def format_money(amount), do: "ZMW #{Decimal.to_string(amount)}"

  def format_date(nil), do: "—"
  def format_date(d), do: Calendar.strftime(d, "%d %b %Y")
end
