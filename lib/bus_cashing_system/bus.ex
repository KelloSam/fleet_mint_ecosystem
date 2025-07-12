defmodule BusCashingSystem.Bus do
  use Ecto.Schema
  import Ecto.Changeset

  schema "buses" do
    field :number, :string
    field :capacity, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bus, attrs) do
    bus
    |> cast(attrs, [:number, :capacity])
    |> validate_required([:number, :capacity])
  end
end
