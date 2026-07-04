defmodule FleetMint.Accounting.LedgerEntry do
  @moduledoc """
  A single-entry cash ledger row. Every real cash movement across the app
  (fares, freight payments, expenditures, operating costs) writes exactly one
  of these. Reversals (e.g. a cancelled booking) never mutate the original
  entry — they insert a new entry linked via `reverses_entry_id`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @entry_types ~w(revenue expense refund adjustment)
  @payment_methods ~w(cash card mobile_money airtel_money mtn_money bank_transfer)

  schema "ledger_entries" do
    field :entry_type, :string
    field :source_type, :string
    field :source_id, :integer
    field :amount, :decimal
    field :payment_method, :string
    field :reference_number, :string
    field :occurred_at, :utc_datetime
    field :description, :string
    field :payment_details, :map

    belongs_to :recorded_by, FleetMint.Identity.User
    belongs_to :reverses_entry, __MODULE__

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :entry_type,
      :source_type,
      :source_id,
      :amount,
      :payment_method,
      :reference_number,
      :occurred_at,
      :description,
      :payment_details,
      :recorded_by_id,
      :reverses_entry_id
    ])
    |> validate_required([:entry_type, :source_type, :source_id, :amount])
    |> validate_inclusion(:entry_type, @entry_types)
    |> validate_inclusion(:payment_method, @payment_methods)
    |> put_default_occurred_at()
    |> validate_amount_by_type()
    |> unique_constraint(:reference_number)
    |> foreign_key_constraint(:recorded_by_id)
    |> foreign_key_constraint(:reverses_entry_id)
  end

  defp put_default_occurred_at(changeset) do
    if get_field(changeset, :occurred_at) do
      changeset
    else
      put_change(changeset, :occurred_at, DateTime.truncate(DateTime.utc_now(), :second))
    end
  end

  defp validate_amount_by_type(changeset) do
    case get_field(changeset, :entry_type) do
      "adjustment" -> validate_number(changeset, :amount, not_equal_to: 0)
      _ -> validate_number(changeset, :amount, greater_than_or_equal_to: 0)
    end
  end
end
