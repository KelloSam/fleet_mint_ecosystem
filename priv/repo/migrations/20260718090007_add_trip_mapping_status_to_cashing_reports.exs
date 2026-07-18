defmodule FleetMint.Repo.Migrations.AddTripMappingStatusToCashingReports do
  use Ecto.Migration

  # Unlike bus_checkpoints (Phase 2a), a cashing_report's link to a Trip
  # cannot be inferred from an existing pseudo-key — it only has bus_id and
  # report_date, and the bus -> vehicle -> schedule bridge those would need
  # is unpopulated in production (buses.vehicle_id is null on every row).
  # So this migration never fabricates a Trip relationship: every report is
  # classified into exactly one of five states, and only the
  # 'automatically_matched' state gets an actual cashing_report_trips row.
  def up do
    alter table(:cashing_reports) do
      add :trip_mapping_status, :string, null: false, default: "pending"
      add :trip_mapping_notes, :text
    end

    create constraint(:cashing_reports, :cashing_reports_trip_mapping_status_check,
             check:
               "trip_mapping_status IN ('pending','automatically_matched','manually_matched','ambiguous','unmappable')")

    # Stage 1 — automatic match: only when exactly one schedule, in the
    # same organisation as the bus, has ever used this bus's vehicle, AND
    # a Trip already exists for that schedule on this report's date. If no
    # such Trip exists yet, this does NOT create one (see Boarding for the
    # only place Trips are created) — the report stays unresolved instead.
    execute """
    WITH candidate_schedules AS (
      SELECT cr.id AS cashing_report_id, s.id AS schedule_id, op.organisation_id
      FROM cashing_reports cr
      JOIN buses b ON b.id = cr.bus_id AND b.vehicle_id IS NOT NULL
      JOIN schedules s ON s.vehicle_id = b.vehicle_id
      JOIN operators op ON op.id = s.operator_id AND op.organisation_id = b.organisation_id
    ),
    schedule_counts AS (
      SELECT cashing_report_id, count(*) AS n FROM candidate_schedules GROUP BY cashing_report_id
    ),
    unique_matches AS (
      SELECT cs.cashing_report_id, cs.schedule_id, cs.organisation_id
      FROM candidate_schedules cs
      JOIN schedule_counts sc ON sc.cashing_report_id = cs.cashing_report_id AND sc.n = 1
    ),
    trip_matches AS (
      SELECT um.cashing_report_id, t.id AS trip_id, um.organisation_id, cr.received_cashing
      FROM unique_matches um
      JOIN cashing_reports cr ON cr.id = um.cashing_report_id
      JOIN trips t ON t.schedule_id = um.schedule_id AND t.travel_date = cr.report_date
    ),
    inserted AS (
      INSERT INTO cashing_report_trips
        (cashing_report_id, trip_id, organisation_id, allocated_amount, match_method, matched_at, inserted_at, updated_at)
      SELECT cashing_report_id, trip_id, organisation_id, received_cashing, 'automatic', now(), now(), now()
      FROM trip_matches
      RETURNING cashing_report_id
    )
    UPDATE cashing_reports
    SET trip_mapping_status = 'automatically_matched',
        trip_mapping_notes = 'Matched to a single trip via bus/vehicle/schedule chain during Phase 2b migration.'
    WHERE id IN (SELECT cashing_report_id FROM inserted)
    """

    # Stage 2 — ambiguous: more than one same-organisation schedule shares
    # this vehicle, so which trip the cash belongs to cannot be inferred.
    # Needs a human to pick (Finance.match_cashing_report_to_trip/4).
    execute """
    WITH candidate_schedules AS (
      SELECT cr.id AS cashing_report_id, s.id AS schedule_id
      FROM cashing_reports cr
      JOIN buses b ON b.id = cr.bus_id AND b.vehicle_id IS NOT NULL
      JOIN schedules s ON s.vehicle_id = b.vehicle_id
      JOIN operators op ON op.id = s.operator_id AND op.organisation_id = b.organisation_id
    ),
    schedule_counts AS (
      SELECT cashing_report_id, count(*) AS n FROM candidate_schedules GROUP BY cashing_report_id
    )
    UPDATE cashing_reports
    SET trip_mapping_status = 'ambiguous',
        trip_mapping_notes = 'Vehicle is assigned to more than one schedule in this organisation; automatic matching cannot determine which trip this cash belongs to. Needs manual reconciliation.'
    WHERE trip_mapping_status = 'pending'
      AND id IN (SELECT cashing_report_id FROM schedule_counts WHERE n > 1)
    """

    # Stage 3 — everything still pending is unmappable, with a specific
    # reason (never a silent blank, never a guess).
    execute """
    UPDATE cashing_reports cr
    SET trip_mapping_status = 'unmappable',
        trip_mapping_notes = CASE
          WHEN cr.bus_id IS NULL THEN
            'No bus recorded on this report.'
          WHEN NOT EXISTS (SELECT 1 FROM buses b WHERE b.id = cr.bus_id AND b.vehicle_id IS NOT NULL) THEN
            'Bus has no vehicle assignment recorded.'
          WHEN NOT EXISTS (
            SELECT 1 FROM buses b JOIN schedules s ON s.vehicle_id = b.vehicle_id WHERE b.id = cr.bus_id
          ) THEN
            'No schedule has ever been assigned this vehicle.'
          WHEN NOT EXISTS (
            SELECT 1 FROM buses b
            JOIN schedules s ON s.vehicle_id = b.vehicle_id
            JOIN operators op ON op.id = s.operator_id AND op.organisation_id = b.organisation_id
            WHERE b.id = cr.bus_id
          ) THEN
            'Vehicle is only used on schedules belonging to a different organisation than the bus record - data integrity issue, flagged for manual review.'
          ELSE
            'A single schedule was found for this vehicle, but no trip is recorded for that schedule on this report date; likely predates Trip tracking.'
        END
    WHERE cr.trip_mapping_status = 'pending'
    """
  end

  def down do
    execute "ALTER TABLE cashing_reports DROP CONSTRAINT cashing_reports_trip_mapping_status_check"

    alter table(:cashing_reports) do
      remove :trip_mapping_notes
      remove :trip_mapping_status
    end
  end
end
