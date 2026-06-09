defmodule FleetMintWeb.BusHTML do
  use FleetMintWeb, :html

  embed_templates "bus_html/*"

  def status_badge(assigns) do
    color =
      case assigns.status do
        "active" -> "bg-green-100 text-green-800"
        "maintenance" -> "bg-yellow-100 text-yellow-800"
        _ -> "bg-gray-100 text-gray-600"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{@color}"}>
      <%= String.capitalize(@status || "unknown") %>
    </span>
    """
  end

  def status_options, do: [{"Active", "active"}, {"Inactive", "inactive"}, {"Maintenance", "maintenance"}]

  def current_year, do: Date.utc_today().year
end
