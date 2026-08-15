defmodule FleetMint.Transport.Fleet.Branch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "branches" do
    field :name, :string
    field :city, :string

    belongs_to :organisation, FleetMint.Identity.Organisation
    has_many :terminals, FleetMint.Transport.Fleet.Terminal

    timestamps(type: :utc_datetime)
  end

  def changeset(branch, attrs) do
    branch
    |> cast(attrs, [:name, :city, :organisation_id])
    |> validate_required([:name, :organisation_id])
    |> unique_constraint([:organisation_id, :name])
    |> foreign_key_constraint(:organisation_id)
  end
end
