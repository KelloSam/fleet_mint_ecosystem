defmodule FleetMint.Repo.Migrations.CreateOrganisations do
  use Ecto.Migration

  def up do
    create table(:organisations) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisations, [:slug])
    create unique_index(:organisations, [:name])
  end

  def down do
    drop table(:organisations)
  end
end
