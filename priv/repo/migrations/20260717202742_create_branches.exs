defmodule FleetMint.Repo.Migrations.CreateBranches do
  use Ecto.Migration

  def up do
    create table(:branches) do
      add :name, :string, null: false
      add :city, :string
      add :operator_id, references(:operators, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:branches, [:operator_id])
    create unique_index(:branches, [:operator_id, :name])
  end

  def down do
    drop table(:branches)
  end
end
