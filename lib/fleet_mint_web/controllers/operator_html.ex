defmodule FleetMintWeb.OperatorHTML do
  use FleetMintWeb, :html
  embed_templates "operator_html/*"

  @doc """
  Fare range across this operator's real schedules for a route, falling
  back to the route's base fare when the operator hasn't scheduled any
  trips on it yet.
  """
  def fare_range([], base_fare), do: "From ZMW #{base_fare}"

  def fare_range(schedules, _base_fare) do
    fares = Enum.map(schedules, & &1.fare)
    min_fare = Enum.min(fares, Decimal)
    max_fare = Enum.max(fares, Decimal)

    if Decimal.equal?(min_fare, max_fare) do
      "ZMW #{min_fare}"
    else
      "ZMW #{min_fare} – #{max_fare}"
    end
  end
end
