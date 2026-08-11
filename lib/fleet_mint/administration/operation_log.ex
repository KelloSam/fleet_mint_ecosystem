defmodule FleetMint.Administration.OperationLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "operation_logs" do
    field :date, :date
    field :title, :string
    field :description, :string
    field :category, :string, default: "general"

    belongs_to :logged_by, FleetMint.Identity.User
    belongs_to :organisation, FleetMint.Identity.Organisation

    timestamps()
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:date, :title, :description, :category, :logged_by_id, :organisation_id])
    |> validate_required([:date, :title, :logged_by_id])
    |> validate_inclusion(:category, category_options() |> Keyword.values())
    |> foreign_key_constraint(:organisation_id)
  end

  def category_options do
    [
      {"General", "general"},
      {"Incident", "incident"},
      {"Maintenance", "maintenance"},
      {"Finance", "finance"},
      {"Staff", "staff"},
      {"Passenger", "passenger"}
    ]
  end
end
