defmodule FleetMint.Finance.CashingReportTrip do
  @moduledoc """
  Allocates (some or all of) a CashingReport's received_cashing to a Trip.
  A join row only exists once a match is established — unmatched reports
  simply carry a `trip_mapping_status` and no row here (see CashingReport).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @match_methods ~w(automatic manual)

  schema "cashing_report_trips" do
    field :allocated_amount, :decimal
    field :match_method, :string
    field :matched_at, :utc_datetime

    belongs_to :cashing_report, FleetMint.Finance.CashingReport
    belongs_to :trip, FleetMint.Transport.Trips.Trip
    belongs_to :organisation, FleetMint.Identity.Organisation
    belongs_to :matched_by, FleetMint.Identity.User, foreign_key: :matched_by_id

    timestamps(type: :utc_datetime)
  end

  def changeset(allocation, attrs) do
    allocation
    |> cast(attrs, [
      :cashing_report_id,
      :trip_id,
      :organisation_id,
      :allocated_amount,
      :match_method,
      :matched_at,
      :matched_by_id
    ])
    |> validate_required([
      :cashing_report_id,
      :trip_id,
      :organisation_id,
      :allocated_amount,
      :match_method,
      :matched_at
    ])
    |> validate_number(:allocated_amount, greater_than: 0)
    |> validate_inclusion(:match_method, @match_methods)
    |> foreign_key_constraint(:cashing_report_id)
    |> foreign_key_constraint(:trip_id)
    |> foreign_key_constraint(:organisation_id)
    |> foreign_key_constraint(:matched_by_id)
    |> unique_constraint([:cashing_report_id, :trip_id])
  end
end
