defmodule FleetMint.Repo.Migrations.AddOperatorIdToSchedules do
  use Ecto.Migration

  def change do
    alter table(:schedules) do
      add :operator_id, references(:operators, on_delete: :nilify_all)
    end

    create index(:schedules, [:operator_id])
  end
end
