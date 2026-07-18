defmodule FleetMint.Repo.Migrations.AddAuditTrackingToFinancialRecords do
  use Ecto.Migration

  def change do
    for table <- [:expenditures, :cashing_reports] do
      alter table(table) do
        add :created_by_id, references(:users, on_delete: :nilify_all)
        add :updated_by_id, references(:users, on_delete: :nilify_all)
        add :archived_at, :naive_datetime, null: true
      end

      create index(table, [:created_by_id])
      create index(table, [:archived_at])
    end
  end
end
