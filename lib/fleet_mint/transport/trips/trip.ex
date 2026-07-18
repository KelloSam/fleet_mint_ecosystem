defmodule FleetMint.Transport.Trips.Trip do
  @moduledoc """
  One actual planned or operating movement of a Schedule on a specific
  day — the Constitution's Route → Schedule → Trip chain. Everything that
  happens during a real journey (checkpoints, and eventually cashing
  reconciliation) hangs off this, not off the Schedule directly, because
  the same Schedule runs many times and each run can have its own actual
  vehicle/crew (breakdown substitutions, relief drivers) without rewriting
  history for every other day that Schedule ran.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(planned dispatched active completed cancelled)

  schema "trips" do
    field :travel_date, :date
    field :status, :string, default: "planned"
    field :departed_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :schedule, FleetMint.Transport.Trips.Schedule
    belongs_to :organisation, FleetMint.Identity.Organisation

    # Overrides of the Schedule's usual assignment for this one day. nil
    # means "use the Schedule's own vehicle_id/driver_id/conductor_id".
    belongs_to :vehicle, FleetMint.Transport.Fleet.Vehicle
    belongs_to :driver, FleetMint.HR.Driver
    belongs_to :conductor, FleetMint.Identity.User

    has_many :checkpoints, FleetMint.Transport.Boarding.BusCheckpoint

    timestamps(type: :utc_datetime)
  end

  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [:travel_date, :status, :departed_at, :completed_at,
                    :schedule_id, :organisation_id, :vehicle_id, :driver_id, :conductor_id])
    |> validate_required([:travel_date, :status, :schedule_id, :organisation_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:schedule_id)
    |> foreign_key_constraint(:organisation_id)
    |> foreign_key_constraint(:vehicle_id)
    |> foreign_key_constraint(:driver_id)
    |> foreign_key_constraint(:conductor_id)
    |> unique_constraint([:schedule_id, :travel_date])
  end

  def status_changeset(trip, status) when status in @statuses do
    change(trip, status: status)
  end
end
