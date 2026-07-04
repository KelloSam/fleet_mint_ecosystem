defmodule FleetMint.Fleet.Vehicle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicles" do
    field :registration_number, :string
    field :make, :string
    field :model, :string
    field :year, :integer
    field :color, :string
    field :vin, :string
    field :vehicle_type, :string, default: "bus"
    field :status, :string, default: "active"
    field :description, :string
    field :archived_at, :naive_datetime

    belongs_to :current_driver, FleetMint.Operations.Driver
    has_one :bus_profile, FleetMint.Fleet.BusProfile
    has_one :truck_profile, FleetMint.Fleet.TruckProfile

    timestamps()
  end

  @vehicle_types ~w(bus truck)
  @statuses ~w(active inactive maintenance decommissioned)

  def changeset(vehicle, attrs) do
    vehicle
    |> cast(attrs, [:registration_number, :make, :model, :year, :color, :vin,
                    :vehicle_type, :status, :description, :current_driver_id])
    |> validate_required([:registration_number, :make, :model, :vehicle_type])
    |> validate_inclusion(:vehicle_type, @vehicle_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:year, greater_than: 1980, less_than_or_equal_to: Date.utc_today().year + 1)
    |> unique_constraint(:registration_number)
  end
end
