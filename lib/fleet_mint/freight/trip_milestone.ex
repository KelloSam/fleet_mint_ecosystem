defmodule FleetMint.Freight.TripMilestone do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trip_milestones" do
    field :location, :string
    field :event_type, :string
    field :event_time, :naive_datetime
    field :latitude, :float
    field :longitude, :float
    field :odometer_reading, :integer
    field :notes, :string
    field :recorded_by, :string

    belongs_to :trip, FleetMint.Freight.Trip

    timestamps()
  end

  @event_types ~w(departed checkpoint fuel_stop border_crossing police_checkpoint arrived incident delay)

  def changeset(milestone, attrs) do
    milestone
    |> cast(attrs, [:location, :event_type, :event_time, :latitude, :longitude,
                    :odometer_reading, :notes, :recorded_by, :trip_id])
    |> validate_required([:location, :event_type, :event_time, :trip_id])
    |> validate_inclusion(:event_type, @event_types)
  end

  def event_type_options do
    [
      {"Departed", "departed"}, {"Checkpoint", "checkpoint"},
      {"Fuel Stop", "fuel_stop"}, {"Border Crossing", "border_crossing"},
      {"Police Checkpoint", "police_checkpoint"}, {"Arrived", "arrived"},
      {"Incident", "incident"}, {"Delay", "delay"}
    ]
  end
end
