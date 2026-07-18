defmodule FleetMint.Repo.Migrations.CreateTrips do
  use Ecto.Migration

  def up do
    create table(:trips) do
      add :schedule_id, references(:schedules, on_delete: :restrict), null: false
      # Denormalized from schedule.operator.organisation_id at creation time.
      # Not just a convenience column: it's the target of the composite
      # (trip_id, organisation_id) foreign keys that bus_checkpoints and
      # (later) cashing_report_trips use, so a child record can never be
      # attached to a Trip belonging to a different organisation even if
      # application code has a bug.
      add :organisation_id, references(:organisations, on_delete: :restrict), null: false

      add :travel_date, :date, null: false
      add :status, :string, null: false, default: "planned"

      # Overrides of the Schedule's usual assignment for this specific day
      # (breakdown substitutions, relief crew, etc.) — nil means "use the
      # Schedule's own vehicle_id/driver_id/conductor_id".
      add :vehicle_id, references(:vehicles, on_delete: :nilify_all)
      add :driver_id, references(:drivers, on_delete: :nilify_all)
      add :conductor_id, references(:users, on_delete: :nilify_all)

      add :departed_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # One Trip per Schedule per day — this is also exactly bus_checkpoints'
    # existing (schedule_id, travel_date) pseudo-key, which is what makes
    # migrating checkpoints onto trip_id unambiguous in the next migration.
    create unique_index(:trips, [:schedule_id, :travel_date])

    # Required by Postgres to support the composite foreign keys child
    # tables use — id alone is already unique, but a composite FK target
    # must itself be a unique constraint on exactly those columns.
    create unique_index(:trips, [:id, :organisation_id])

    create index(:trips, [:organisation_id])
    create index(:trips, [:vehicle_id])
    create index(:trips, [:driver_id])

    create constraint(:trips, :trips_status_check,
             check: "status IN ('planned','dispatched','active','completed','cancelled')")
  end

  def down do
    drop table(:trips)
  end
end
