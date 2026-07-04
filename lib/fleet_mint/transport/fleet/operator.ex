defmodule FleetMint.Transport.Fleet.Operator do
  use Ecto.Schema
  import Ecto.Changeset

  schema "operators" do
    field :name, :string
    field :slug, :string
    field :tagline, :string
    field :contact_phone, :string
    field :contact_email, :string
    field :color, :string, default: "#1d4ed8"
    field :active, :boolean, default: true
    field :archived_at, :naive_datetime

    field :schedule_count, :integer, virtual: true

    has_many :schedules, FleetMint.Transport.Trips.Schedule
    many_to_many :routes, FleetMint.Transport.Fleet.Route,
      join_through: "operator_routes",
      on_replace: :delete

    timestamps()
  end

  def changeset(operator, attrs) do
    operator
    |> cast(attrs, [:name, :slug, :tagline, :contact_phone, :contact_email, :color, :active])
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
