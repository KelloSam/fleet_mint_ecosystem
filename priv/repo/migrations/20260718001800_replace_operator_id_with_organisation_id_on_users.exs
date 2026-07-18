defmodule FleetMint.Repo.Migrations.ReplaceOperatorIdWithOrganisationIdOnUsers do
  use Ecto.Migration

  def up do
    # operator_id was added the same day and is nil for every existing user
    # (confirmed: neither of the two accounts had been assigned one yet), so
    # this is a straight swap, not a data migration.
    drop index(:users, [:operator_id])

    alter table(:users) do
      remove :operator_id
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:users, [:organisation_id])
  end

  def down do
    drop index(:users, [:organisation_id])

    alter table(:users) do
      remove :organisation_id
      add :operator_id, references(:operators, on_delete: :nilify_all)
    end

    create index(:users, [:operator_id])
  end
end
