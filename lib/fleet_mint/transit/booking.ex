defmodule FleetMint.Transit.Booking do
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

    belongs_to :schedule, FleetMint.Transit.Schedule
    belongs_to :booked_by, FleetMint.Accounts.User
    has_one :ticket, FleetMint.Transit.Ticket

    timestamps()
  end

  @statuses ~w(confirmed cancelled checked_in no_show)
  @payment_methods ~w(cash airtel_money mtn_money card bank_transfer)

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:passenger_name, :passenger_phone, :passenger_email, :seat_number,
                    :travel_date, :status, :fare_paid, :payment_method, :payment_reference,
                    :notes, :schedule_id, :booked_by_id])
    |> validate_required([:passenger_name, :travel_date, :fare_paid, :schedule_id])
    |> validate_number(:fare_paid, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:payment_method, @payment_methods)
    |> generate_reference()
    |> unique_constraint(:booking_reference)
  end

  defp generate_reference(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    ref = "BK-#{:rand.uniform(9999999) |> Integer.to_string() |> String.pad_leading(7, "0")}"
    put_change(changeset, :booking_reference, ref)
  end
  defp generate_reference(changeset), do: changeset
end
