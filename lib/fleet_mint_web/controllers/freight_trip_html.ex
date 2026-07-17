defmodule FleetMintWeb.FreightTripHTML do
  use FleetMintWeb, :html

  embed_templates "freight_trip_html/*"

  def status_badge(assigns) do
    color =
      case assigns.status do
        "scheduled" -> "bg-gray-100 text-gray-700"
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
      {"Scheduled", "scheduled"},
      {"Loading", "loading"},
      {"In Transit", "in_transit"},
      {"Delivered", "delivered"},
      {"Cancelled", "cancelled"}
    ]

  def next_statuses("scheduled"), do: ["loading", "cancelled"]
  def next_statuses("loading"), do: ["in_transit", "cancelled"]
  def next_statuses("in_transit"), do: ["delivered"]
  def next_statuses(_), do: []

  def vehicle_options(vehicles), do: Enum.map(vehicles, &{"#{&1.registration_number} (#{&1.make} #{&1.model})", &1.id})
  def driver_options(drivers), do: Enum.map(drivers, &{&1.name, &1.id})

  def format_money(nil), do: "—"
  def format_money(amount), do: "ZMW #{Decimal.to_string(amount)}"

  def format_datetime(nil), do: "—"
  def format_datetime(dt), do: Calendar.strftime(dt, "%d %b %Y %H:%M")

  def event_type_label(type) do
    Enum.find_value(FleetMint.Cargo.TripMilestone.event_type_options(), type, fn {label, value} ->
      if value == type, do: label
    end)
  end
end
