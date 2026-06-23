defmodule FleetMint.Transit.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schedules" do
    field :schedule_code, :string
    field :departure_time, :time
    field :estimated_arrival_time, :time
    field :days_of_week, {:array, :string}, default: []
    field :fare, :decimal
    field :available_seats, :integer, default: 0
    field :status, :string, default: "active"
    field :validation_mode, :string, default: "static"
    field :notes, :string

    belongs_to :vehicle, FleetMint.Fleet.Vehicle
    belongs_to :route, FleetMint.Fleet.Route
    belongs_to :driver, FleetMint.Accounts.User
    belongs_to :conductor, FleetMint.Accounts.User
    belongs_to :operator, FleetMint.Fleet.Operator

    has_many :bookings, FleetMint.Transit.Booking

    timestamps()
  end

  @valid_days ~w(mon tue wed thu fri sat sun)
  @statuses ~w(active cancelled suspended)
  @validation_modes ~w(static live)

  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [:schedule_code, :departure_time, :estimated_arrival_time, :days_of_week,
                    :fare, :available_seats, :status, :validation_mode, :notes,
                    :vehicle_id, :route_id, :driver_id, :conductor_id, :operator_id])
    |> validate_required([:departure_time, :fare, :route_id])
    |> validate_number(:fare, greater_than: 0)
    |> validate_number(:available_seats, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:validation_mode, @validation_modes)
    |> validate_days()
    |> maybe_generate_code()
    |> unique_constraint(:schedule_code)
  end

  defp validate_days(changeset) do
    case get_change(changeset, :days_of_week) do
      nil -> changeset
      days ->
        invalid = Enum.reject(days, &(&1 in @valid_days))
        if Enum.empty?(invalid), do: changeset,
          else: add_error(changeset, :days_of_week, "invalid day(s): #{Enum.join(invalid, ", ")}")
    end
  end

  defp maybe_generate_code(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    if get_field(changeset, :schedule_code) do
      changeset
    else
      suffix = :crypto.strong_rand_bytes(3) |> Base.encode16()
      put_change(changeset, :schedule_code, "SCH-#{suffix}")
    end
  end
  defp maybe_generate_code(changeset), do: changeset
end
