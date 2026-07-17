defmodule FleetMint.Transport.Ticketing.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :booking_reference, :string
    field :passenger_name, :string
    field :passenger_phone, :string
    field :passenger_email, :string
    field :seat_number, :string
    field :travel_date, :date
    field :status, :string, default: "confirmed"
    field :fare_paid, :decimal
    field :payment_method, :string, default: "cash"
    field :payment_reference, :string
    field :notes, :string
    field :pickup_station, :string
    field :has_luggage, :boolean, default: false
    field :luggage_description, :string

    belongs_to :schedule, FleetMint.Transport.Trips.Schedule
    belongs_to :booked_by, FleetMint.Identity.User
    belongs_to :terminal, FleetMint.Transport.Fleet.Terminal
    has_one :ticket, FleetMint.Transport.Ticketing.Ticket

    timestamps()
  end

  @statuses ~w(confirmed cancelled checked_in no_show)
  @payment_methods ~w(cash airtel_money mtn_money card bank_transfer)

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:passenger_name, :passenger_phone, :passenger_email, :seat_number,
                    :travel_date, :status, :fare_paid, :payment_method, :payment_reference,
                    :notes, :pickup_station, :has_luggage, :luggage_description,
                    :schedule_id, :booked_by_id, :terminal_id])
    |> validate_required([:passenger_name, :travel_date, :fare_paid, :schedule_id])
    |> validate_number(:fare_paid, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:payment_method, @payment_methods)
    |> generate_reference()
    |> unique_constraint(:booking_reference)
    |> unique_constraint(:seat_number,
      name: :bookings_active_seat_unique,
      message: "seat is already booked for this schedule and date"
    )
    |> foreign_key_constraint(:terminal_id)
  end

  def internal_changeset(booking, attrs) do
    booking
    |> changeset(attrs)
    |> validate_required([:booked_by_id])
  end

  defp generate_reference(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    suffix = :crypto.strong_rand_bytes(4) |> Base.encode16()
    put_change(changeset, :booking_reference, "BK-#{suffix}")
  end
  defp generate_reference(changeset), do: changeset
end
