defmodule FleetMint.Repo.Migrations.AddDateToExpendituresAndUpdateForeignKey do
  use Ecto.Migration

  def change do
    alter table(:expenditures) do
      # Add date field
      add :date, :naive_datetime
    end

    # Drop existing foreign key and index
    drop_if_exists index(:expenditures, [:cashing_report_id])
    
    # Update foreign key constraint
    execute "ALTER TABLE expenditures DROP CONSTRAINT IF EXISTS expenditures_cashing_report_id_fkey"
    
    alter table(:expenditures) do
      modify :cashing_report_id, references(:cashing_reports, on_delete: :delete_all)
    end

    # Recreate the index
    create index(:expenditures, [:cashing_report_id])
  end
end
