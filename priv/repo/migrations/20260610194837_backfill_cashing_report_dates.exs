defmodule FleetMint.Repo.Migrations.BackfillCashingReportDates do
  use Ecto.Migration

  def up do
    execute """
    UPDATE cashing_reports
    SET report_date = DATE(inserted_at)
    WHERE report_date IS NULL
    """
  end

  def down do
    # Not reversible — we don't know which records had report_date as nil before
    :ok
  end
end
