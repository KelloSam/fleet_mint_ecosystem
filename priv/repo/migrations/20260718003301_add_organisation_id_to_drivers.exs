defmodule FleetMint.Repo.Migrations.AddOrganisationIdToDrivers do
  use Ecto.Migration

  def up do
    alter table(:drivers) do
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:drivers, [:organisation_id])
  end

  def down do
    drop index(:drivers, [:organisation_id])

    alter table(:drivers) do
      remove :organisation_id
    end
  end
end
