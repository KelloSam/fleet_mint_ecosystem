defmodule BusCashingSystem.Ticketing.Ticket do
  use Ecto.Schema
  import Ecto.Changeset
  alias BusCashingSystem.Fleet.{Route, Bus}
  alias BusCashingSystem.Accounts.User

  @valid_statuses ["valid", "cancelled", "used"]

  @doc """
  The Ticket schema represents a ticket issued to a passenger for a bus journey.
  It is linked to a route, bus, and the user (cashier) who issued it.
  """
  schema "tickets" do
    field :status, :string
    field :ticket_number, :string
    field :passenger_name, :string
    field :seat_number, :string
    field :fare_amount, :decimal
    field :travel_date, :date
    field :departure_time, :time
    
    belongs_to :route, Route
    belongs_to :bus, Bus
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Generates a unique ticket number using current timestamp and random string.
  Format: TKT-{YYYYMMDD}-{6 random alphanumeric characters}
  """
  def generate_ticket_number do
    date_part = Date.utc_today() |> Date.to_string() |> String.replace("-", "")
    random_part = for _ <- 1..6, into: "", do: <<Enum.random("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.to_charlist())>>
    "TKT-#{date_part}-#{random_part}"
  end

  @doc """
  Changeset for creating and updating tickets with validations.

  Validates that:
  - All required fields are present
  - The ticket number is unique
  - The status is one of the valid statuses
  - The travel date is present or in the future
  - The fare amount is positive
  - The passenger name and seat number meet format requirements
  - The associations to route, bus, and user are valid
  """
  def changeset(ticket, attrs) do
    # Generate ticket number if not provided
    attrs = if attrs[:ticket_number] || attrs["ticket_number"] do
      attrs
    else
      Map.put(attrs, "ticket_number", generate_ticket_number())
    end

    ticket
    |> cast(attrs, [:ticket_number, :passenger_name, :seat_number, :fare_amount, :status, :travel_date, :departure_time, :route_id, :bus_id, :user_id])
    |> validate_required([:ticket_number, :passenger_name, :seat_number, :fare_amount, :status, :travel_date, :departure_time, :route_id, :bus_id, :user_id])
    |> validate_length(:passenger_name, min: 3, max: 100, message: "must be between 3 and 100 characters")
    |> validate_length(:seat_number, min: 1, max: 10, message: "must be between 1 and 10 characters")
    |> validate_number(:fare_amount, greater_than: 0, message: "must be greater than 0")
    |> validate_inclusion(:status, @valid_statuses, message: "must be one of: #{Enum.join(@valid_statuses, ", ")}")
    |> validate_travel_date()
    |> unique_constraint(:ticket_number)
    |> foreign_key_constraint(:route_id)
    |> foreign_key_constraint(:bus_id)
    |> foreign_key_constraint(:user_id)
  end

  # Validates that the travel date is today or in the future.
  defp validate_travel_date(changeset) do
    case get_field(changeset, :travel_date) do
      nil -> changeset
      travel_date ->
        today = Date.utc_today()
        
        if Date.compare(travel_date, today) in [:eq, :gt] do
          changeset
        else
          add_error(changeset, :travel_date, "must be today or in the future")
        end
    end
  end
end
