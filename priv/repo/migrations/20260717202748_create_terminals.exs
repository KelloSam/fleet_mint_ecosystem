defmodule FleetMint.Repo.Migrations.CreateTerminals do
  use Ecto.Migration

  def up do
    create table(:terminals) do
      add :name, :string, null: false
      add :address, :string
      add :branch_id, references(:branches, on_delete: :delete_all), null: false
      # Denormalized from branches.operator_id so tenant-scoped queries can
      # filter terminals directly without joining through branches.
      add :operator_id, references(:operators, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:terminals, [:branch_id])
    create index(:terminals, [:operator_id])
    create unique_index(:terminals, [:branch_id, :name])
  end

  def down do
    drop table(:terminals)
  end
end
