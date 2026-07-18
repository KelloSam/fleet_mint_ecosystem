defmodule FleetMint.Repo.Migrations.AddOrganisationIdToAuditLogs do
  use Ecto.Migration

  # Nullable on purpose: audit_logs has no reliable link to a tenant for
  # events with no actor (failed/blocked login attempts against an unknown
  # email) - those stay organisation_id NULL, meaning platform-only
  # visible, which is the honest and safe default for an event that can't
  # be attributed to a tenant. Events with a known actor are backfilled
  # from that actor's *current* organisation_id - a reasonable best
  # effort (an audit event surfaced to a tenant admin this way is always
  # about one of their own org's own users, never a leak), not a claim
  # about what the actor's organisation was at the historical time of the
  # event.
  def up do
    alter table(:audit_logs) do
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:audit_logs, [:organisation_id])

    execute """
    UPDATE audit_logs al
    SET organisation_id = u.organisation_id
    FROM users u
    WHERE al.actor_id = u.id AND al.organisation_id IS NULL
    """
  end

  def down do
    drop index(:audit_logs, [:organisation_id])

    alter table(:audit_logs) do
      remove :organisation_id
    end
  end
end
