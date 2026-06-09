defmodule FleetMint.Repo.Migrations.CreateCashingReports do
  use Ecto.Migration

  def change do
    create table(:cashing_reports) do
      add :days_worked, :integer
      add :expected_cashing, :decimal
      add :received_cashing, :decimal
      add :airtel_id, :string
      add :debt_balance, :decimal
      add :expenditure, :decimal
      add :description, :text
      add :report_id, references(:weekly_reports, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:cashing_reports, [:report_id])
  end
end
