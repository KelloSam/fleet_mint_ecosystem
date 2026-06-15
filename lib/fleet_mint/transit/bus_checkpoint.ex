defmodule FleetMint.Transit.BusCheckpoint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bus_checkpoints" do
    field :location, :string
    field :notes, :string
    field :travel_date, :date

    belongs_to :schedule, FleetMint.Transit.Schedule
    belongs_to :reported_by, FleetMint.Accounts.User

    timestamps(updated_at: false)
  end

  def changeset(checkpoint, attrs) do
    checkpoint
    |> cast(attrs, [:location, :notes, :travel_date, :schedule_id, :reported_by_id])
    |> validate_required([:location, :travel_date, :schedule_id])
    |> validate_length(:location, min: 2, max: 200)
  end
end
