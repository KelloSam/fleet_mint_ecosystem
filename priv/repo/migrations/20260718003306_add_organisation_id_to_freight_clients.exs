defmodule FleetMint.Repo.Migrations.AddOrganisationIdToFreightClients do
  use Ecto.Migration

  def up do
    alter table(:freight_clients) do
      add :organisation_id, references(:organisations, on_delete: :nilify_all)
    end

    create index(:freight_clients, [:organisation_id])
  end

  def down do
    drop index(:freight_clients, [:organisation_id])

    alter table(:freight_clients) do
      remove :organisation_id
    end
  end
end
