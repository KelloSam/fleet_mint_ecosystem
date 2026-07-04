defmodule FleetMint.Operations.Driver do
  use Ecto.Schema
  import Ecto.Changeset

  schema "drivers" do
    field :name, :string
    field :phone, :string
    field :license_number, :string
    field :license_expiry, :date
    field :daily_rate, :decimal
    field :date_hired, :date
    field :status, :string, default: "active"
    field :notes, :string
    field :archived_at, :naive_datetime

    belongs_to :user, FleetMint.Identity.User

    timestamps()
  end

  def changeset(driver, attrs) do
    driver
    |> cast(attrs, [:name, :phone, :license_number, :license_expiry, :daily_rate, :date_hired, :status, :notes, :user_id])
    |> validate_required([:name])
    |> validate_inclusion(:status, status_options() |> Keyword.values())
    |> unique_constraint(:license_number)
  end

  def status_options do
    [{"Active", "active"}, {"Inactive", "inactive"}, {"Suspended", "suspended"}]
  end

  def license_expired?(%__MODULE__{license_expiry: nil}), do: false
  def license_expired?(%__MODULE__{license_expiry: expiry}), do: Date.compare(expiry, Date.utc_today()) == :lt
end
