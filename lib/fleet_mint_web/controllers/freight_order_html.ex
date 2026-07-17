defmodule FleetMintWeb.FreightOrderHTML do
  use FleetMintWeb, :html

  embed_templates "freight_order_html/*"

  def status_badge(assigns) do
    color =
      case assigns.status do
        "pending" -> "bg-gray-100 text-gray-700"
        "assigned" -> "bg-blue-100 text-blue-800"
        "loading" -> "bg-amber-100 text-amber-800"
        "in_transit" -> "bg-indigo-100 text-indigo-800"
        "delivered" -> "bg-green-100 text-green-800"
        "cancelled" -> "bg-red-100 text-red-800"
        _ -> "bg-gray-100 text-gray-600"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{@color}"}>
      <%= String.replace(@status || "unknown", "_", " ") |> String.capitalize() %>
    </span>
    """
  end

  def status_options,
    do: [
      {"Pending", "pending"},
      {"Assigned", "assigned"},
      {"Loading", "loading"},
      {"In Transit", "in_transit"},
      {"Delivered", "delivered"},
      {"Cancelled", "cancelled"}
    ]

  def cargo_type_label(type) do
    Enum.find_value(FleetMint.Cargo.Order.cargo_type_options(), type, fn {label, value} ->
      if value == type, do: label
    end)
  end

  def client_options(clients), do: Enum.map(clients, &{&1.company_name, &1.id})
  def trip_options(trips), do: Enum.map(trips, &{"#{&1.trip_reference} (#{&1.origin} → #{&1.destination})", &1.id})

  def format_money(nil), do: "—"
  def format_money(amount), do: "ZMW #{Decimal.to_string(amount)}"

  def format_weight(nil), do: "—"
  def format_weight(w), do: "#{Decimal.to_string(w)} t"

  def format_date(nil), do: "—"
  def format_date(d), do: Calendar.strftime(d, "%d %b %Y")
end
