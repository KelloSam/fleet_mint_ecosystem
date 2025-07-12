defmodule BusCashingSystem.Payments.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias BusCashingSystem.Ticketing.Ticket
  alias BusCashingSystem.Accounts.User

  @valid_payment_methods ["cash", "card", "mobile_money"]
  @valid_statuses ["success", "failed", "pending"]

  @doc """
  The Transaction schema represents a payment transaction for a ticket.
  It tracks the payment method, amount, status, and other details of a payment
  made by a passenger and processed by a cashier.
  """
  schema "transactions" do
    field :status, :string
    field :payment_method, :string
    field :amount, :decimal
    field :reference_number, :string
    field :transaction_date, :utc_datetime
    field :payment_details, :map
    
    belongs_to :ticket, Ticket
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Generates a unique reference number for a transaction.
  Format: TXN-{YYYYMMDDHHMMSS}-{6 random alphanumeric characters}
  """
  def generate_reference_number do
    timestamp = DateTime.utc_now()
    datetime_part = timestamp
                    |> DateTime.to_string()
                    |> String.replace(["-", ":", ".", " "], "")
                    |> String.slice(0, 14)
    random_part = for _ <- 1..6, into: "", do: <<Enum.random("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.to_charlist())>>
    "TXN-#{datetime_part}-#{random_part}"
  end

  @doc """
  Changeset for creating and updating transactions with validations.

  Validates that:
  - All required fields are present
  - The payment method is one of the valid payment methods
  - The status is one of the valid statuses
  - The amount is positive
  - The reference number is unique
  - The payment details is a map (if provided)
  - The associations to ticket and user are valid

  Automatically sets:
  - A unique reference number if not provided
  - The transaction date to the current UTC datetime if not provided
  """
  def changeset(transaction, attrs) do
    # Generate reference number if not provided
    attrs = if attrs[:reference_number] || attrs["reference_number"] do
      attrs
    else
      Map.put(attrs, "reference_number", generate_reference_number())
    end

    # Set transaction date to current UTC datetime if not provided
    attrs = if attrs[:transaction_date] || attrs["transaction_date"] do
      attrs
    else
      Map.put(attrs, "transaction_date", DateTime.utc_now())
    end

    transaction
    |> cast(attrs, [:payment_method, :amount, :status, :reference_number, :transaction_date, :payment_details, :ticket_id, :user_id])
    |> validate_required([:payment_method, :amount, :status, :reference_number, :transaction_date, :ticket_id, :user_id])
    |> validate_inclusion(:payment_method, @valid_payment_methods, message: "must be one of: #{Enum.join(@valid_payment_methods, ", ")}")
    |> validate_inclusion(:status, @valid_statuses, message: "must be one of: #{Enum.join(@valid_statuses, ", ")}")
    |> validate_number(:amount, greater_than: 0, message: "must be greater than 0")
    |> validate_payment_details()
    |> unique_constraint(:reference_number)
    |> foreign_key_constraint(:ticket_id)
    |> foreign_key_constraint(:user_id)
  end

  # Validates that payment_details is a map if provided.
  defp validate_payment_details(changeset) do
    case get_field(changeset, :payment_details) do
      nil -> changeset
      payment_details when is_map(payment_details) -> changeset
      _ -> add_error(changeset, :payment_details, "must be a map")
    end
  end
end
