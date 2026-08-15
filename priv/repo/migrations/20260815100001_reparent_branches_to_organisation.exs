defmodule FleetMint.Repo.Migrations.ReparentBranchesToOrganisation do
  use Ecto.Migration

  def up do
    # branches has 0 rows in every environment checked (dev confirmed
    # 2026-08-15) — this is a straight swap, not a data migration. Branch
    # inherited the same tenant-root defect Phase 1 already corrected
    # Operator out of: an Organisation may have no Operator profile at all
    # (logistics hubs, government departments, school transport bases), so
    # Branch must trace to Organisation directly, not through Operator.
    drop index(:branches, [:operator_id])
    drop index(:branches, [:operator_id, :name])

    alter table(:branches) do
      remove :operator_id
      add :organisation_id, references(:organisations, on_delete: :delete_all), null: false
    end

    create index(:branches, [:organisation_id])
    create unique_index(:branches, [:organisation_id, :name])
  end

  def down do
    drop index(:branches, [:organisation_id])
    drop index(:branches, [:organisation_id, :name])

    alter table(:branches) do
      remove :organisation_id
      add :operator_id, references(:operators, on_delete: :delete_all), null: false
    end

    create index(:branches, [:operator_id])
    create unique_index(:branches, [:operator_id, :name])
  end
end
