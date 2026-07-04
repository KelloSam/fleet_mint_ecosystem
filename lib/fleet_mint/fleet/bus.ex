defmodule FleetMint.Fleet.Bus do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses ["active", "inactive", "maintenance"]
  @min_year 2000
  @current_year 2025
  schema "buses" do
    field :status, :string
    field :description, :string
    field :year, :integer
    field :registration_number, :string
    field :capacity, :integer
    field :model, :string

    belongs_to :vehicle, FleetMint.Fleet.Vehicle

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating and updating buses with validations.
  """
  def changeset(bus, attrs) do
    bus
    |> cast(attrs, [:registration_number, :capacity, :model, :year, :status, :description, :vehicle_id])
    |> validate_required([:registration_number, :capacity, :model, :year, :status])
    |> validate_format(:registration_number, ~r/^[A-Z0-9]+$/, message: "must contain only uppercase letters and numbers")
    |> validate_number(:capacity, greater_than: 0, message: "must be greater than 0")
    |> validate_number(:year, greater_than_or_equal_to: @min_year, less_than_or_equal_to: @current_year + 1, 
       message: "must be between #{@min_year} and #{@current_year + 1}")
    |> validate_inclusion(:status, @valid_statuses, message: "must be one of: #{Enum.join(@valid_statuses, ", ")}")
    |> unique_constraint(:registration_number)
  end
end
