defmodule FleetMint.Repo.Migrations.CreateExpenditures do
  use Ecto.Migration

  def change do
    create table(:expenditures) do
      add :amount, :decimal
      add :description, :text
      add :cashing_report_id, references(:cashing_reports, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:expenditures, [:cashing_report_id])
  end
end
