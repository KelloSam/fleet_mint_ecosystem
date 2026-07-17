defmodule FleetMint.Transport.Fleet.Terminal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "terminals" do
    field :name, :string
    field :address, :string

    belongs_to :branch, FleetMint.Transport.Fleet.Branch
    belongs_to :operator, FleetMint.Transport.Fleet.Operator

    timestamps(type: :utc_datetime)
  end

  def changeset(terminal, attrs) do
    terminal
    |> cast(attrs, [:name, :address, :branch_id, :operator_id])
    |> validate_required([:name, :branch_id, :operator_id])
    |> unique_constraint([:branch_id, :name])
    |> foreign_key_constraint(:branch_id)
    |> foreign_key_constraint(:operator_id)
  end
end
