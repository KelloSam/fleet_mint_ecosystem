defmodule FleetMint.Transit.MinibusTrip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "minibus_trips" do
    field :date, :date
    field :status, :string, default: "scheduled"
    field :passengers_count, :integer, default: 0
    field :fare_collected, :decimal
    field :fuel_cost, :decimal
    field :notes, :string

    belongs_to :bus, FleetMint.Fleet.Bus
    belongs_to :route, FleetMint.Fleet.Route
    belongs_to :driver, FleetMint.Accounts.User

    timestamps()
  end

  @statuses ~w(scheduled in_progress completed cancelled)

  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [:date, :status, :passengers_count, :fare_collected, :fuel_cost,
                    :notes, :bus_id, :route_id, :driver_id])
    |> validate_required([:date, :bus_id, :route_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:passengers_count, greater_than_or_equal_to: 0)
    |> validate_number(:fare_collected, greater_than_or_equal_to: 0)
    |> validate_number(:fuel_cost, greater_than_or_equal_to: 0)
  end

  def status_options, do: [
    {"Scheduled", "scheduled"},
    {"In Progress", "in_progress"},
    {"Completed", "completed"},
    {"Cancelled", "cancelled"}
  ]

  def profit(%{fare_collected: fare, fuel_cost: fuel})
      when not is_nil(fare) and not is_nil(fuel),
      do: Decimal.sub(fare, fuel)
  def profit(_), do: Decimal.new(0)
end
