defmodule FleetMintWeb.RouteHTML do
  use FleetMintWeb, :html

  embed_templates "route_html/*"

  def status_badge(assigns) do
    color =
      case assigns.status do
        "active" -> "bg-green-100 text-green-800"
        _ -> "bg-gray-100 text-gray-600"
      end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{@color}"}>
      <%= String.capitalize(@status || "unknown") %>
    </span>
    """
  end

  def status_options, do: [{"Active", "active"}, {"Inactive", "inactive"}]

  def format_fare(nil), do: "—"
  def format_fare(fare), do: "ZMW #{Decimal.to_string(fare)}"

  def format_distance(nil), do: "—"
  def format_distance(d), do: "#{Decimal.to_string(d)} km"

  def format_duration(nil), do: "—"
  def format_duration(mins) when mins >= 60 do
    h = div(mins, 60)
    m = rem(mins, 60)
    if m == 0, do: "#{h}h", else: "#{h}h #{m}m"
  end
  def format_duration(mins), do: "#{mins}m"
end
