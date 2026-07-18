defmodule FleetMint.Identity.Organisation do
  @moduledoc """
  The tenant root (the Constitution's "Company"). A transport business,
  logistics company, or institution using FleetMint — everything a tenant
  owns (staff, an optional passenger-transport `Operator` brand, freight
  clients, vehicles) traces back to one of these.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "organisations" do
    field :name, :string
    field :slug, :string
    field :active, :boolean, default: true

    has_many :users, FleetMint.Identity.User
    has_one :operator, FleetMint.Transport.Fleet.Operator

    timestamps(type: :utc_datetime)
  end

  def changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name, :slug, :active])
    |> validate_required([:name, :slug])
    |> update_change(:slug, &slugify/1)
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
