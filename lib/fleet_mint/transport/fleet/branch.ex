defmodule FleetMint.Transport.Fleet.Branch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "branches" do
    field :name, :string
    field :city, :string

    belongs_to :operator, FleetMint.Transport.Fleet.Operator
    has_many :terminals, FleetMint.Transport.Fleet.Terminal

    timestamps(type: :utc_datetime)
  end

  def changeset(branch, attrs) do
    branch
    |> cast(attrs, [:name, :city, :operator_id])
    |> validate_required([:name, :operator_id])
    |> unique_constraint([:operator_id, :name])
    |> foreign_key_constraint(:operator_id)
  end
end
