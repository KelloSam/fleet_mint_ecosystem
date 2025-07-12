defmodule BusCashingSystem.Finance.Report do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weekly_reports" do
    field :start_date, :date
    field :end_date, :date

    has_many :cashing_reports, BusCashingSystem.Finance.CashingReport, foreign_key: :report_id
    
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:start_date, :end_date])
    |> validate_required([:start_date, :end_date])
  end
end

