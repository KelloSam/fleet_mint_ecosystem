defmodule FleetMint.Repo.Migrations.AddTripIdToBusCheckpoints do
  use Ecto.Migration

  def up do
    alter table(:bus_checkpoints) do
      add :trip_id, :bigint
      add :organisation_id, :bigint
    end

    # Every checkpoint's (schedule_id, travel_date) is exactly a Trip's
    # natural key — create the Trip if this is the first checkpoint to
    # reference that (schedule, day) pair.
    execute """
    INSERT INTO trips (schedule_id, organisation_id, travel_date, status, inserted_at, updated_at)
    SELECT DISTINCT bc.schedule_id, o.organisation_id, bc.travel_date, 'planned', now(), now()
    FROM bus_checkpoints bc
    JOIN schedules s ON s.id = bc.schedule_id
    JOIN operators o ON o.id = s.operator_id
    WHERE NOT EXISTS (
      SELECT 1 FROM trips t
      WHERE t.schedule_id = bc.schedule_id AND t.travel_date = bc.travel_date
    )
    """

    execute """
    UPDATE bus_checkpoints bc
    SET trip_id = t.id, organisation_id = t.organisation_id
    FROM trips t
    WHERE t.schedule_id = bc.schedule_id AND t.travel_date = bc.travel_date
    """

    # Every checkpoint's schedule_id is itself NOT NULL and FK-constrained
    # (see Boarding.BusCheckpoint.changeset), and every schedule has an
    # operator with an organisation (Phase 1 migration), so the join above
    # is total by construction. This is a hard stop, not a guess: if it
    # ever fires, some checkpoint's schedule/operator chain is broken and
    # that must be fixed by hand before this migration can proceed safely.
    execute """
    DO $$
    DECLARE unmapped_count integer;
    BEGIN
      SELECT count(*) INTO unmapped_count FROM bus_checkpoints WHERE trip_id IS NULL;
      IF unmapped_count > 0 THEN
        RAISE EXCEPTION '% bus_checkpoints could not be mapped to a Trip — schedule_id/operator/organisation chain is broken for these rows, refusing to guess', unmapped_count;
      END IF;
    END $$;
    """

    alter table(:bus_checkpoints) do
      modify :trip_id, :bigint, null: false
      modify :organisation_id, :bigint, null: false
    end

    create index(:bus_checkpoints, [:trip_id])
    create index(:bus_checkpoints, [:organisation_id])

    # Composite FK: a checkpoint's trip_id must point at a Trip whose
    # organisation_id equals the checkpoint's own — this is the actual
    # tenant-isolation enforcement (a plain FK on trip_id alone would only
    # prove the Trip exists, not that it belongs to the same organisation).
    execute """
    ALTER TABLE bus_checkpoints
    ADD CONSTRAINT bus_checkpoints_trip_organisation_fkey
    FOREIGN KEY (trip_id, organisation_id)
    REFERENCES trips (id, organisation_id)
    ON DELETE RESTRICT
    """

    # schedule_id/travel_date stay on bus_checkpoints for now (not dropped)
    # — they're superseded by trip_id but removing them is a separate,
    # later cleanup once the app has run on trip_id in production for a
    # while, per "remove obsolete columns only after verification".
  end

  def down do
    execute "ALTER TABLE bus_checkpoints DROP CONSTRAINT bus_checkpoints_trip_organisation_fkey"
    drop index(:bus_checkpoints, [:organisation_id])
    drop index(:bus_checkpoints, [:trip_id])

    alter table(:bus_checkpoints) do
      remove :organisation_id
      remove :trip_id
    end
  end
end
