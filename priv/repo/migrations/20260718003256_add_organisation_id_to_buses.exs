defmodule FleetMint.Repo.Migrations.AddOrganisationIdToBuses do
  use Ecto.Migration

  def up do
    alter table(:buses) do
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:buses, [:organisation_id])
  end

  def down do
    drop index(:buses, [:organisation_id])

    alter table(:buses) do
      remove :organisation_id
    end
  end
end
