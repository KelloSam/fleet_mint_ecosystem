defmodule FleetMint.Freight.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "freight_orders" do
    field :order_reference, :string
    field :cargo_type, :string
    field :cargo_description, :string
    field :weight_tons, :decimal
    field :volume_cbm, :decimal
    field :origin, :string
    field :destination, :string
    field :pickup_date, :date
    field :delivery_deadline, :date
    field :declared_value, :decimal
    field :agreed_rate, :decimal
    field :status, :string, default: "pending"
    field :special_instructions, :string
    field :requires_refrigeration, :boolean, default: false
    field :hazmat_class, :string

    belongs_to :client, FleetMint.Freight.Client
    belongs_to :assigned_trip, FleetMint.Freight.Trip
    belongs_to :created_by, FleetMint.Identity.User

    timestamps()
  end

  @statuses ~w(pending assigned loading in_transit delivered cancelled)
  @cargo_types ~w(copper_ore coal cobalt_ore agricultural_produce maize fertilizer cement
                  fuel general_cargo hazardous refrigerated timber steel)

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:cargo_type, :cargo_description, :weight_tons, :volume_cbm,
                    :origin, :destination, :pickup_date, :delivery_deadline,
                    :declared_value, :agreed_rate, :status, :special_instructions,
                    :requires_refrigeration, :hazmat_class,
                    :client_id, :assigned_trip_id, :created_by_id])
    |> validate_required([:cargo_type, :origin, :destination, :client_id])
    |> validate_inclusion(:cargo_type, @cargo_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:weight_tons, greater_than: 0)
    |> validate_number(:agreed_rate, greater_than_or_equal_to: 0)
    |> generate_reference()
    |> unique_constraint(:order_reference)
  end

  def cargo_type_options do
    [
      {"Copper Ore", "copper_ore"}, {"Coal", "coal"}, {"Cobalt Ore", "cobalt_ore"},
      {"Agricultural Produce", "agricultural_produce"}, {"Maize", "maize"},
      {"Fertilizer", "fertilizer"}, {"Cement", "cement"}, {"Fuel", "fuel"},
      {"General Cargo", "general_cargo"}, {"Hazardous Material", "hazardous"},
      {"Refrigerated Goods", "refrigerated"}, {"Timber", "timber"}, {"Steel / Metal", "steel"}
    ]
  end

  defp generate_reference(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    suffix = :crypto.strong_rand_bytes(4) |> Base.encode16()
    put_change(changeset, :order_reference, "ORD-#{suffix}")
  end
  defp generate_reference(changeset), do: changeset
end
