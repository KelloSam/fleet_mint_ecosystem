defmodule FleetMint.Repo.Migrations.DropTerminalsOperatorId do
  use Ecto.Migration

  def up do
    # Redundant once Terminal derives tenant through branch -> organisation
    # (one hop through Branch, matching the Phase 1 rule: "if a table's
    # tenant is one hop away via an association, join through it rather
    # than denormalizing a redundant column"). terminals has 0 rows in
    # every environment checked (dev confirmed 2026-08-15).
    drop index(:terminals, [:operator_id])

    alter table(:terminals) do
      remove :operator_id
    end
  end

  def down do
    alter table(:terminals) do
      add :operator_id, references(:operators, on_delete: :delete_all), null: false
    end

    create index(:terminals, [:operator_id])
  end
end
