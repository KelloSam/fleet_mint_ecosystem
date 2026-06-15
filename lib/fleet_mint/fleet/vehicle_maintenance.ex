defmodule FleetMint.Fleet.VehicleMaintenance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicle_maintenances" do
    field :service_date, :date
    field :service_type, :string
    field :description, :string
    field :cost, :decimal
    field :mileage_at_service, :integer
    field :next_service_date, :date
    field :next_service_mileage, :integer
    field :garage, :string
    field :status, :string, default: "completed"

    belongs_to :vehicle, FleetMint.Fleet.Vehicle
    belongs_to :recorded_by, FleetMint.Accounts.User, foreign_key: :recorded_by_id

    timestamps()
  end

  @service_types ~w(oil_change tire_replacement brake_service full_service engine_repair
                    transmission gearbox electrical bodywork inspection other)
  @statuses ~w(scheduled in_progress completed)

  def changeset(maintenance, attrs) do
    maintenance
    |> cast(attrs, [:service_date, :service_type, :description, :cost, :mileage_at_service,
                    :next_service_date, :next_service_mileage, :garage, :status,
                    :vehicle_id, :recorded_by_id])
    |> validate_required([:service_date, :service_type, :vehicle_id])
    |> validate_inclusion(:service_type, @service_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:cost, greater_than_or_equal_to: 0)
  end

  def service_type_options, do: [
    {"Oil Change", "oil_change"},
    {"Tire Replacement", "tire_replacement"},
    {"Brake Service", "brake_service"},
    {"Full Service", "full_service"},
    {"Engine Repair", "engine_repair"},
    {"Transmission / Gearbox", "transmission"},
    {"Electrical", "electrical"},
    {"Bodywork", "bodywork"},
    {"Inspection", "inspection"},
    {"Other", "other"}
  ]

  def status_options, do: [
    {"Scheduled", "scheduled"},
    {"In Progress", "in_progress"},
    {"Completed", "completed"}
  ]
end
