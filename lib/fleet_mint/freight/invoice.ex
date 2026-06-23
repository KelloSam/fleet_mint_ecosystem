defmodule FleetMint.Freight.Invoice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "freight_invoices" do
    field :invoice_number, :string
    field :invoice_date, :date
    field :due_date, :date
    field :base_amount, :decimal
    field :fuel_surcharge, :decimal, default: Decimal.new(0)
    field :toll_surcharge, :decimal, default: Decimal.new(0)
    field :vat_amount, :decimal, default: Decimal.new(0)
    field :total_amount, :decimal
    field :status, :string, default: "draft"
    field :payment_date, :date
    field :payment_reference, :string
    field :notes, :string

    belongs_to :client, FleetMint.Freight.Client
    belongs_to :trip, FleetMint.Freight.Trip
    belongs_to :created_by, FleetMint.Accounts.User

    timestamps()
  end

  @statuses ~w(draft issued paid overdue cancelled)

  defp vat_rate do
    Application.get_env(:fleet_mint, :vat_rate, "0.16") |> Decimal.new()
  end

  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:invoice_date, :due_date, :base_amount, :fuel_surcharge,
                    :toll_surcharge, :vat_amount, :total_amount, :status,
                    :payment_date, :payment_reference, :notes,
                    :client_id, :trip_id, :created_by_id])
    |> validate_required([:invoice_date, :base_amount, :client_id, :trip_id])
    |> validate_number(:base_amount, greater_than: 0)
    |> validate_inclusion(:status, @statuses)
    |> compute_totals()
    |> generate_invoice_number()
    |> unique_constraint(:invoice_number)
  end

  defp compute_totals(changeset) do
    base = get_field(changeset, :base_amount) || Decimal.new(0)
    fuel = get_field(changeset, :fuel_surcharge) || Decimal.new(0)
    toll = get_field(changeset, :toll_surcharge) || Decimal.new(0)
    subtotal = Decimal.add(base, Decimal.add(fuel, toll))
    vat = Decimal.mult(subtotal, vat_rate()) |> Decimal.round(2)
    total = Decimal.add(subtotal, vat) |> Decimal.round(2)
    changeset
    |> put_change(:vat_amount, vat)
    |> put_change(:total_amount, total)
  end

  defp generate_invoice_number(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    year = Date.utc_today().year
    suffix = :crypto.strong_rand_bytes(3) |> Base.encode16()
    put_change(changeset, :invoice_number, "INV-#{year}-#{suffix}")
  end
  defp generate_invoice_number(changeset), do: changeset
end
