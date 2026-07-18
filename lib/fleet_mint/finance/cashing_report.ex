defmodule FleetMint.Finance.CashingReport do
  use Ecto.Schema
  import Ecto.Changeset

  @trip_mapping_statuses ~w(pending automatically_matched manually_matched ambiguous unmappable)

  schema "cashing_reports" do
    field :description, :string
    field :days_worked, :integer
    field :expected_cashing, :decimal
    field :received_cashing, :decimal
    field :airtel_id, :string
    field :debt_balance, :decimal
    field :expenditure, :decimal
    field :report_date, :date

    # System-managed reconciliation state — never cast in the public
    # changeset below. Only Finance.attempt_trip_match/1 (automatic) and
    # Finance.match_cashing_report_to_trip/4 (manual) may change these,
    # via mapping_status_changeset/2.
    field :trip_mapping_status, :string, default: "pending"
    field :trip_mapping_notes, :string

    belongs_to :report, FleetMint.Finance.Report
    belongs_to :bus, FleetMint.Transport.Fleet.Bus
    belongs_to :conductor, FleetMint.Identity.User, foreign_key: :conductor_id
    has_many :expenditures, FleetMint.Finance.Expenditure, foreign_key: :cashing_report_id
    has_many :cashing_report_trips, FleetMint.Finance.CashingReportTrip
    has_many :trips, through: [:cashing_report_trips, :trip]

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

  @doc """
  Changeset for the Trip-reconciliation state only — kept separate from
  `changeset/2` so no controller form can set trip_mapping_status directly.
  """
  def mapping_status_changeset(cashing_report, attrs) do
    cashing_report
    |> cast(attrs, [:trip_mapping_status, :trip_mapping_notes])
    |> validate_required([:trip_mapping_status])
    |> validate_inclusion(:trip_mapping_status, @trip_mapping_statuses)
  end
end

