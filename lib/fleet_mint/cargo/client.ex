defmodule FleetMint.Cargo.Client do
  use Ecto.Schema
  import Ecto.Changeset

  schema "freight_clients" do
    field :company_name, :string
    field :contact_person, :string
    field :phone, :string
    field :email, :string
    field :address, :string
    field :city, :string
    field :client_type, :string, default: "general_business"
    field :tpin, :string
    field :credit_limit, :decimal, default: Decimal.new(0)
    field :credit_balance, :decimal, default: Decimal.new(0)
    field :status, :string, default: "active"
    field :notes, :string

    has_many :orders, FleetMint.Cargo.Order
    has_many :invoices, FleetMint.Cargo.Invoice

    timestamps()
  end

  @client_types ~w(mining_company farm general_business individual government ngo)
  @statuses ~w(active suspended blacklisted)

  def changeset(client, attrs) do
    client
    |> cast(attrs, [:company_name, :contact_person, :phone, :email, :address, :city,
                    :client_type, :tpin, :credit_limit, :credit_balance, :status, :notes])
    |> validate_required([:company_name, :client_type])
    |> validate_inclusion(:client_type, @client_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:credit_limit, greater_than_or_equal_to: 0)
  end

  def type_options do
    [
      {"Mining Company", "mining_company"}, {"Farm / Agricultural", "farm"},
      {"General Business", "general_business"}, {"Individual", "individual"},
      {"Government", "government"}, {"NGO / Charity", "ngo"}
    ]
  end
end
