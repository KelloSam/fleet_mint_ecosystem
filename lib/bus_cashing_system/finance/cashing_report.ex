defmodule BusCashingSystem.Finance.CashingReport do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cashing_reports" do
    field :description, :string
    field :days_worked, :integer
    field :expected_cashing, :decimal
    field :received_cashing, :decimal
    field :airtel_id, :string
    field :debt_balance, :decimal
    field :expenditure, :decimal
    
    belongs_to :report, BusCashingSystem.Finance.Report
    has_many :expenditures, BusCashingSystem.Finance.Expenditure, foreign_key: :cashing_report_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cashing_report, attrs) do
    cashing_report
    |> cast(attrs, [:days_worked, :expected_cashing, :received_cashing, :airtel_id, :debt_balance, :expenditure, :description, :report_id])
    |> validate_required([:days_worked, :expected_cashing, :received_cashing, :airtel_id, :debt_balance, :expenditure, :description, :report_id])
  end
end

