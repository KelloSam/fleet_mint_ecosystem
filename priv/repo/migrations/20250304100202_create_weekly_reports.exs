defmodule BusCashingSystem.Repo.Migrations.CreateWeeklyReports do
  use Ecto.Migration

  def change do
    create table(:weekly_reports) do
      add :start_date, :date
      add :end_date, :date

      timestamps(type: :utc_datetime)
    end
  end
end
