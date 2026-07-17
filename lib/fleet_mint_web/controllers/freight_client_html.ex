defmodule FleetMintWeb.FreightClientHTML do
  use FleetMintWeb, :html

  embed_templates "freight_client_html/*"

  def status_badge(assigns) do
    color =
      case assigns.status do
        "active" -> "bg-green-100 text-green-800"
        "suspended" -> "bg-amber-100 text-amber-800"
        "blacklisted" -> "bg-red-100 text-red-800"
        _ -> "bg-gray-100 text-gray-600"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{@color}"}>
      <%= String.capitalize(@status || "unknown") %>
    </span>
    """
  end

  def status_options, do: [{"Active", "active"}, {"Suspended", "suspended"}, {"Blacklisted", "blacklisted"}]

  def type_label(type) do
    Enum.find_value(FleetMint.Cargo.Client.type_options(), type, fn {label, value} ->
      if value == type, do: label
    end)
  end

  def format_money(nil), do: "—"
  def format_money(amount), do: "ZMW #{Decimal.to_string(amount)}"
end
