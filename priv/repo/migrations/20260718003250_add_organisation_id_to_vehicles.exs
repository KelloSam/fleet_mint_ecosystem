defmodule FleetMint.Repo.Migrations.AddOrganisationIdToVehicles do
  use Ecto.Migration

  def up do
    alter table(:vehicles) do
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:vehicles, [:organisation_id])
  end

  def down do
    drop index(:vehicles, [:organisation_id])

    alter table(:vehicles) do
      remove :organisation_id
    end
  end
end
