defmodule FleetMint.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :event,       :string, null: false
      add :actor_id,    :integer
      add :actor_email, :string
      add :target_type, :string
      add :target_id,   :string
      add :metadata,    :map, default: %{}
      add :ip_address,  :string

      timestamps(updated_at: false)
    end

    create index(:audit_logs, [:inserted_at])
    create index(:audit_logs, [:actor_id])
    create index(:audit_logs, [:event])
  end
end
