defmodule FleetMint.Transit.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :ticket_number, :string
    field :qr_payload, :string
    field :qr_svg, :string
    field :status, :string, default: "issued"
    field :boarded_at, :naive_datetime
    field :validation_token, :string
    field :expires_at, :naive_datetime

    belongs_to :booking, FleetMint.Transit.Booking

    timestamps()
  end

  @statuses ~w(issued boarded cancelled expired)

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:ticket_number, :qr_payload, :qr_svg, :status,
                    :boarded_at, :validation_token, :expires_at, :booking_id])
    |> validate_required([:booking_id])
    |> validate_inclusion(:status, @statuses)
    |> generate_ticket_number()
    |> unique_constraint(:ticket_number)
    |> unique_constraint(:booking_id)
  end

  def board_changeset(ticket) do
    change(ticket, status: "boarded", boarded_at: NaiveDateTime.utc_now())
  end

  defp generate_ticket_number(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    num = "TKT-#{:rand.uniform(999999999) |> Integer.to_string() |> String.pad_leading(9, "0")}"
    put_change(changeset, :ticket_number, num)
  end
  defp generate_ticket_number(changeset), do: changeset
end
