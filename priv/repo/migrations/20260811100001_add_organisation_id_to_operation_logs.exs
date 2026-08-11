defmodule FleetMint.Repo.Migrations.AddOrganisationIdToOperationLogs do
  use Ecto.Migration

  # Nullable, same reasoning as audit_logs (20260718100007): a log with no
  # resolvable actor stays organisation_id NULL (platform-only visible)
  # rather than guessed into a tenant. Existing rows are backfilled from
  # logged_by_id's *current* organisation_id - going forward,
  # OperationLogController forces organisation_id from the creating
  # user's own scope at create time (same pattern as buses/vehicles),
  # not this derivation.
  def up do
    alter table(:operation_logs) do
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:operation_logs, [:organisation_id])

    execute """
    UPDATE operation_logs ol
    SET organisation_id = u.organisation_id
    FROM users u
    WHERE ol.logged_by_id = u.id AND ol.organisation_id IS NULL
    """
  end

  def down do
    drop index(:operation_logs, [:organisation_id])

    alter table(:operation_logs) do
      remove :organisation_id
    end
  end
end
