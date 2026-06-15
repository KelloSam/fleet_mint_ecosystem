defmodule FleetMint.Repo.Migrations.CreateOperationLogs do
  use Ecto.Migration

  def change do
    create table(:operation_logs) do
      add :date, :date, null: false
      add :title, :string, null: false
      add :description, :text
      add :category, :string, default: "general"
      add :logged_by_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:operation_logs, [:date])
    create index(:operation_logs, [:logged_by_id])
  end
end
