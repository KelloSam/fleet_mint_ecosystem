defmodule FleetMint.Transport.Fleet.FuelLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fuel_logs" do
    field :log_date, :date
    field :liters, :decimal
    field :cost_per_liter, :decimal
    field :total_cost, :decimal
    field :mileage, :integer
    field :fuel_station, :string
    field :fuel_type, :string, default: "diesel"
    field :notes, :string

    belongs_to :vehicle, FleetMint.Transport.Fleet.Vehicle
    belongs_to :driver, FleetMint.Operations.Driver, foreign_key: :driver_id
    belongs_to :recorded_by, FleetMint.Identity.User, foreign_key: :recorded_by_id

    timestamps()
  end

  @fuel_types ~w(diesel petrol)

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:log_date, :liters, :cost_per_liter, :total_cost, :mileage,
                    :fuel_station, :fuel_type, :notes, :vehicle_id, :driver_id, :recorded_by_id])
    |> validate_required([:log_date, :liters, :vehicle_id])
    |> validate_number(:liters, greater_than: 0)
    |> validate_inclusion(:fuel_type, @fuel_types)
    |> compute_total_cost()
  end

  defp compute_total_cost(changeset) do
    liters = get_field(changeset, :liters)
    cpp = get_field(changeset, :cost_per_liter)
    if liters && cpp && is_nil(get_field(changeset, :total_cost)) do
      put_change(changeset, :total_cost, Decimal.mult(liters, cpp) |> Decimal.round(2))
    else
      changeset
    end
  end

  def fuel_type_options, do: [{"Diesel", "diesel"}, {"Petrol", "petrol"}]
end
