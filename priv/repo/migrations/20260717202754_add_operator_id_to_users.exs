defmodule FleetMint.Repo.Migrations.AddOperatorIdToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      # NULL means platform-level (Miway staff) — sees across every operator.
      # Set means the user is that operator's own tenant staff, scoped to
      # their data only.
      add :operator_id, references(:operators, on_delete: :nilify_all)
    end

    create index(:users, [:operator_id])
  end

  def down do
    drop index(:users, [:operator_id])

    alter table(:users) do
      remove :operator_id
    end
  end
end
