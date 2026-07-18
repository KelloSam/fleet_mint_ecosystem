defmodule FleetMint.Repo.Migrations.CreateCashingReportTrips do
  use Ecto.Migration

  def up do
    create table(:cashing_report_trips) do
      add :cashing_report_id, references(:cashing_reports, on_delete: :delete_all), null: false
      # Denormalized from the matched Trip's own organisation_id — this is
      # the target of the composite (trip_id, organisation_id) foreign key
      # below, the same tenant-isolation pattern used for bus_checkpoints.
      add :organisation_id, references(:organisations, on_delete: :restrict), null: false
      add :trip_id, :bigint, null: false

      # How much of the report's received_cashing is attributed to this
      # trip. Usually the full amount (one report, one trip) but split
      # allocation across several trips is allowed for reports that cover
      # more than one day's/trip's cash in a single submission.
      add :allocated_amount, :decimal, null: false

      add :match_method, :string, null: false
      add :matched_at, :utc_datetime, null: false
      add :matched_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cashing_report_trips, [:cashing_report_id, :trip_id])
    create index(:cashing_report_trips, [:organisation_id])
    create index(:cashing_report_trips, [:trip_id])

    create constraint(:cashing_report_trips, :cashing_report_trips_match_method_check,
             check: "match_method IN ('automatic','manual')")

    # Composite FK: an allocation's trip_id must point at a Trip whose
    # organisation_id equals the allocation's own — a plain trip_id FK
    # alone would only prove the Trip exists, not that it's the same
    # tenant's Trip. Mirrors bus_checkpoints_trip_organisation_fkey.
    execute """
    ALTER TABLE cashing_report_trips
    ADD CONSTRAINT cashing_report_trips_trip_organisation_fkey
    FOREIGN KEY (trip_id, organisation_id)
    REFERENCES trips (id, organisation_id)
    ON DELETE RESTRICT
    """
  end

  def down do
    drop table(:cashing_report_trips)
  end
end
