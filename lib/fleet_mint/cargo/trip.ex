defmodule FleetMint.Cargo.Trip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "freight_trips" do
    field :trip_reference, :string
    field :origin, :string
    field :destination, :string
    field :planned_departure, :naive_datetime
    field :actual_departure, :naive_datetime
    field :planned_arrival, :naive_datetime
    field :actual_arrival, :naive_datetime
    field :status, :string, default: "scheduled"
    field :current_location, :string
    field :odometer_start, :integer
    field :odometer_end, :integer
    field :fuel_used_liters, :decimal
    field :toll_fees, :decimal, default: Decimal.new(0)
    field :other_expenses, :decimal, default: Decimal.new(0)
    field :notes, :string

    belongs_to :vehicle, FleetMint.Transport.Fleet.Vehicle
    belongs_to :driver, FleetMint.HR.Driver
    belongs_to :co_driver, FleetMint.HR.Driver
    belongs_to :created_by, FleetMint.Identity.User

    has_many :orders, FleetMint.Cargo.Order, foreign_key: :assigned_trip_id
    has_many :milestones, FleetMint.Cargo.TripMilestone
    has_many :invoices, FleetMint.Cargo.Invoice

    timestamps()
  end

  @statuses ~w(scheduled loading in_transit delivered cancelled)

  def changeset(trip, attrs) do
    trip
    |> cast(attrs, [:origin, :destination, :planned_departure, :actual_departure,
                    :planned_arrival, :actual_arrival, :status, :current_location,
                    :odometer_start, :odometer_end, :fuel_used_liters, :toll_fees,
                    :other_expenses, :notes, :vehicle_id, :driver_id, :co_driver_id, :created_by_id])
    |> validate_required([:origin, :destination, :vehicle_id])
    |> validate_inclusion(:status, @statuses)
    |> generate_reference()
    |> unique_constraint(:trip_reference)
  end

  def total_expenses(trip) do
    toll = Decimal.new(trip.toll_fees || 0)
    other = Decimal.new(trip.other_expenses || 0)
    Decimal.add(toll, other)
  end

  defp generate_reference(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    ref = "FT-#{Date.utc_today() |> Calendar.strftime("%y%m%d")}-#{:rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")}"
    put_change(changeset, :trip_reference, ref)
  end
  defp generate_reference(changeset), do: changeset
end
