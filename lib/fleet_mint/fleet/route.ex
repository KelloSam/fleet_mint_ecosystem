defmodule FleetMint.Fleet.Route do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses ["active", "inactive"]
  schema "routes" do
    field :name, :string
    field :status, :string
    field :description, :string
    field :end_location, :string
    field :start_location, :string
    field :distance, :decimal
    field :duration, :integer
    field :fare, :decimal
    field :stops, {:array, :string}, default: []
    field :archived_at, :naive_datetime

    many_to_many :operators, FleetMint.Fleet.Operator,
      join_through: "operator_routes"

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating and updating routes with validations.

  Validates that:
  - All required fields are present (name, start_location, end_location, distance, duration, fare, status)
  - The route name is unique
  - The distance, duration, and fare are positive numbers
  - The status is one of the valid statuses (active, inactive)
  - Description is optional
  """
  def changeset(route, attrs) do
    route
    |> cast(attrs, [:name, :start_location, :end_location, :distance, :duration, :fare, :status, :description, :stops])
    |> validate_required([:name, :start_location, :end_location, :distance, :duration, :fare, :status])
    |> validate_number(:distance, greater_than: 0, message: "must be greater than 0")
    |> validate_number(:duration, greater_than: 0, message: "must be greater than 0")
    |> validate_number(:fare, greater_than: 0, message: "must be greater than 0")
    |> validate_inclusion(:status, @valid_statuses, 
       message: "must be one of: #{Enum.join(@valid_statuses, ", ")}")
    |> unique_constraint(:name)
  end
end
