defmodule BusCashingSystem.Expenditures.Expenditure do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expenditures" do
    field :description, :string
    field :amount, :decimal
    field :date, :date
    field :category, :string
    field :notes, :string
    
    belongs_to :user, BusCashingSystem.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(expenditure, attrs) do
    expenditure
    |> cast(attrs, [:description, :amount, :date, :category, :notes, :user_id])
    |> validate_required([:description, :amount, :date, :category, :user_id])
    |> validate_number(:amount, greater_than: 0)
    |> foreign_key_constraint(:user_id)
  end
end

