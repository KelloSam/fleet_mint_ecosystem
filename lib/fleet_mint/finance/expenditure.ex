defmodule FleetMint.Finance.Expenditure do
  @moduledoc """
  The Expenditure schema represents a financial expenditure record in the system.
  
  Expenditures are associated with cashing reports and include amount, description,
  and date details. Each expenditure represents a cost incurred in bus operations.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias FleetMint.Finance.CashingReport

  schema "expenditures" do
    field :amount, :decimal
    field :description, :string
    field :date, :naive_datetime
    belongs_to :cashing_report, CashingReport

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating and updating expenditures.
  
  Validates that:
  - Amount, description, and date are required
  - Amount is greater than zero
  - Associated cashing report exists
  """
  def changeset(expenditure, attrs) do
    expenditure
    |> cast(attrs, [:amount, :description, :date, :cashing_report_id])
    |> validate_required([:amount, :description, :date, :cashing_report_id])
    |> validate_number(:amount, greater_than: 0, message: "must be greater than 0")
    |> foreign_key_constraint(:cashing_report_id)
  end
end
