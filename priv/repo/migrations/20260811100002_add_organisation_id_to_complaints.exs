defmodule FleetMint.Repo.Migrations.AddOrganisationIdToComplaints do
  use Ecto.Migration

  # Nullable: complaints come from an unauthenticated public form with no
  # operator/org selector, so most have no reliable tenant link at all -
  # those stay organisation_id NULL, meaning platform-only visible (never
  # guessed), consistent with audit_logs/operation_logs. The one real
  # signal available is an optional free-text booking_reference typed by
  # the passenger - where it happens to match a real booking, we can
  # trace booking -> schedule -> operator -> organisation and backfill
  # that. This is intentionally best-effort: it only derives a match when
  # `bookings.booking_reference` matches exactly, and does nothing for
  # complaints with no reference or a typo'd one.
  def up do
    alter table(:complaints) do
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:complaints, [:organisation_id])

    execute """
    UPDATE complaints c
    SET organisation_id = o.organisation_id
    FROM bookings b
    JOIN schedules s ON s.id = b.schedule_id
    JOIN operators o ON o.id = s.operator_id
    WHERE c.booking_reference = b.booking_reference
      AND c.booking_reference IS NOT NULL
      AND c.organisation_id IS NULL
    """
  end

  def down do
    drop index(:complaints, [:organisation_id])

    alter table(:complaints) do
      remove :organisation_id
    end
  end
end
