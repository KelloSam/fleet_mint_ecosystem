defmodule FleetMint.Transport.Fleet.TruckProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "truck_profiles" do
    field :payload_capacity_tons, :decimal
    field :cargo_volume_cbm, :decimal
    field :axle_configuration, :string
    field :truck_category, :string, default: "rigid"
    field :allowed_cargo_types, {:array, :string}, default: []
    field :refrigerated, :boolean, default: false
    field :gvw_kg, :integer

    belongs_to :vehicle, FleetMint.Transport.Fleet.Vehicle

    timestamps()
  end

  @truck_categories ~w(rigid articulated tipper flatbed tanker lowbed)
  @cargo_types ~w(copper_ore coal cobalt_ore agricultural_produce maize fertilizer cement
                  fuel general_cargo hazardous refrigerated timber steel)

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:payload_capacity_tons, :cargo_volume_cbm, :axle_configuration,
                    :truck_category, :allowed_cargo_types, :refrigerated, :gvw_kg, :vehicle_id])
    |> validate_required([:payload_capacity_tons, :vehicle_id])
    |> validate_number(:payload_capacity_tons, greater_than: 0)
    |> validate_inclusion(:truck_category, @truck_categories)
    |> validate_cargo_types()
    |> unique_constraint(:vehicle_id)
  end

  defp validate_cargo_types(changeset) do
    case get_change(changeset, :allowed_cargo_types) do
      nil -> changeset
      types ->
        invalid = Enum.reject(types, &(&1 in @cargo_types))
        if Enum.empty?(invalid), do: changeset,
          else: add_error(changeset, :allowed_cargo_types, "invalid: #{Enum.join(invalid, ", ")}")
    end
  end

  def cargo_type_options do
    [
      {"Copper Ore", "copper_ore"}, {"Coal", "coal"}, {"Cobalt Ore", "cobalt_ore"},
      {"Agricultural Produce", "agricultural_produce"}, {"Maize", "maize"},
      {"Fertilizer", "fertilizer"}, {"Cement", "cement"}, {"Fuel", "fuel"},
      {"General Cargo", "general_cargo"}, {"Hazardous", "hazardous"},
      {"Refrigerated", "refrigerated"}, {"Timber", "timber"}, {"Steel", "steel"}
    ]
  end
end
