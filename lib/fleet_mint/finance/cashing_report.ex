defmodule FleetMint.Finance.CashingReport do
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
    field :report_date, :date

    belongs_to :report, FleetMint.Finance.Report
    belongs_to :bus, FleetMint.Transport.Fleet.Bus
    belongs_to :conductor, FleetMint.Identity.User, foreign_key: :conductor_id
    has_many :expenditures, FleetMint.Finance.Expenditure, foreign_key: :cashing_report_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cashing_report, attrs) do
    cashing_report
    |> cast(attrs, [:days_worked, :expected_cashing, :received_cashing, :airtel_id, :debt_balance,
                    :expenditure, :description, :report_id, :bus_id, :conductor_id, :report_date])
    |> validate_required([:days_worked, :expected_cashing, :received_cashing,
                          :debt_balance, :expenditure, :description, :report_id, :report_date])
    |> validate_number(:expected_cashing, greater_than_or_equal_to: 0)
    |> validate_number(:received_cashing, greater_than_or_equal_to: 0)
    |> validate_number(:expenditure, greater_than_or_equal_to: 0)
  end
end

