defmodule FleetMint.Transport.Fleet.BusProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bus_profiles" do
    field :seating_capacity, :integer, default: 0
    field :standing_capacity, :integer, default: 0
    field :amenities,    {:array, :string}, default: []
    field :route_type,   :string, default: "urban"
    field :seat_labels,  {:array, :string}, default: []

    belongs_to :vehicle, FleetMint.Transport.Fleet.Vehicle
    belongs_to :current_route, FleetMint.Transport.Routes.Route

    timestamps()
  end

  @route_types ~w(urban intercity rural express)
  @valid_amenities ~w(ac wifi luggage_rack wheelchair_ramp usb_charging reclining_seats)

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:seating_capacity, :standing_capacity, :amenities, :route_type,
                    :seat_labels, :vehicle_id, :current_route_id])
    |> validate_required([:seating_capacity, :vehicle_id])
    |> validate_number(:seating_capacity, greater_than: 0)
    |> validate_number(:standing_capacity, greater_than_or_equal_to: 0)
    |> validate_inclusion(:route_type, @route_types)
    |> validate_amenities()
    |> maybe_generate_seat_labels()
    |> unique_constraint(:vehicle_id)
  end

  defp validate_amenities(changeset) do
    case get_change(changeset, :amenities) do
      nil -> changeset
      amenities ->
        invalid = Enum.reject(amenities, &(&1 in @valid_amenities))
        if Enum.empty?(invalid), do: changeset,
          else: add_error(changeset, :amenities, "contains invalid amenity: #{Enum.join(invalid, ", ")}")
    end
  end

  defp maybe_generate_seat_labels(changeset) do
    case {get_field(changeset, :seat_labels), get_field(changeset, :seating_capacity)} do
      {[], cap} when is_integer(cap) and cap > 0 ->
        put_change(changeset, :seat_labels, generate_labels(cap))
      _ ->
        changeset
    end
  end

  defp generate_labels(capacity) do
    cols = ["A", "B", "C", "D"]
    for n <- 1..capacity do
      row = div(n - 1, 4) + 1
      col = Enum.at(cols, rem(n - 1, 4))
      "#{row}#{col}"
    end
  end
end
