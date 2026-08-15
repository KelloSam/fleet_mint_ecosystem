defmodule FleetMint.Transport.Fleet.Terminal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "terminals" do
    field :name, :string
    field :address, :string

    belongs_to :branch, FleetMint.Transport.Fleet.Branch

    timestamps(type: :utc_datetime)
  end

  def changeset(terminal, attrs) do
    terminal
    |> cast(attrs, [:name, :address, :branch_id])
    |> validate_required([:name, :branch_id])
    |> unique_constraint([:branch_id, :name])
    |> foreign_key_constraint(:branch_id)
  end
end
