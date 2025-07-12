defmodule BusCashingSystem.Route do
  use Ecto.Schema
  import Ecto.Changeset

  schema "routes" do
    field :name, :string
    field :start_point, :string
    field :end_point, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(route, attrs) do
    route
    |> cast(attrs, [:name, :start_point, :end_point])
    |> validate_required([:name, :start_point, :end_point])
  end
end
