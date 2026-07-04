defmodule FleetMint.Operations.OperationLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "operation_logs" do
    field :date, :date
    field :title, :string
    field :description, :string
    field :category, :string, default: "general"

    belongs_to :logged_by, FleetMint.Identity.User

    timestamps()
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:date, :title, :description, :category, :logged_by_id])
    |> validate_required([:date, :title, :logged_by_id])
    |> validate_inclusion(:category, category_options() |> Keyword.values())
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
