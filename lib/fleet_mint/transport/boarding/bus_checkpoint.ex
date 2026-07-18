defmodule FleetMint.Transport.Boarding.BusCheckpoint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bus_checkpoints" do
    field :location, :string
    field :notes, :string
    field :travel_date, :date

    belongs_to :schedule, FleetMint.Transport.Trips.Schedule
    belongs_to :reported_by, FleetMint.Identity.User
    belongs_to :trip, FleetMint.Transport.Trips.Trip
    belongs_to :organisation, FleetMint.Identity.Organisation

    timestamps(updated_at: false)
  end

  @doc """
  `trip_id`/`organisation_id` are not accepted here — they're the tenant
  boundary and are set by `Boarding.post_checkpoint/1` from the resolved
  Trip, never from caller-supplied attrs (see `changeset/3`).
  """
  def changeset(checkpoint, attrs) do
    checkpoint
    |> cast(attrs, [:location, :notes, :travel_date, :schedule_id, :reported_by_id])
    |> validate_required([:location, :travel_date, :schedule_id])
    |> validate_length(:location, min: 2, max: 200)
  end

  @doc false
  def changeset(checkpoint, attrs, %FleetMint.Transport.Trips.Trip{} = trip) do
    checkpoint
    |> changeset(attrs)
    |> put_change(:trip_id, trip.id)
    |> put_change(:organisation_id, trip.organisation_id)
    |> validate_required([:trip_id, :organisation_id])
    |> foreign_key_constraint(:trip_id)
    |> foreign_key_constraint(:organisation_id)
  end
end
