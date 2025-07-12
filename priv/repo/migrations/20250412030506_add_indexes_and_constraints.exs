defmodule BusCashingSystem.Repo.Migrations.AddIndexesAndConstraints do
  use Ecto.Migration

  def change do
    # 1. Add indexes for faster lookups
    # Add index on airtel_id in cashing_reports for payment lookups
    create index(:cashing_reports, [:airtel_id])
    
    # Add composite index on report_id and days_worked for efficient report queries
    create index(:cashing_reports, [:report_id, :days_worked])
    
    # Add index on date in expenditures for date-based queries
    create index(:expenditures, [:date])
    
    # 2. Update foreign key constraints
    # First drop the existing index and constraint
    drop_if_exists index(:cashing_reports, [:report_id])
    execute "ALTER TABLE cashing_reports DROP CONSTRAINT IF EXISTS cashing_reports_report_id_fkey"
    
    # Then recreate with on_delete: :delete_all
    alter table(:cashing_reports) do
      modify :report_id, references(:weekly_reports, on_delete: :delete_all)
    end
    
    # Recreate the index
    create index(:cashing_reports, [:report_id])
    
    # 3. Add decimal constraints for financial fields
    # Create check constraints to ensure valid decimal values
    create constraint(:cashing_reports, :expected_cashing_must_be_positive, check: "expected_cashing >= 0")
    create constraint(:cashing_reports, :received_cashing_must_be_positive, check: "received_cashing >= 0")
    create constraint(:cashing_reports, :expenditure_must_be_positive, check: "expenditure >= 0")
    
    # Debt balance can be negative (representing money owed)
    create constraint(:expenditures, :amount_must_be_positive, check: "amount >= 0")
  end
end
