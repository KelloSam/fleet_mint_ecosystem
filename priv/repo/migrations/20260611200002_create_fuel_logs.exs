defmodule FleetMint.Repo.Migrations.CreateFuelLogs do
  use Ecto.Migration

  def change do
    create table(:fuel_logs) do
      add :log_date, :date, null: false
      add :liters, :decimal, null: false
      add :cost_per_liter, :decimal
      add :total_cost, :decimal
      add :mileage, :integer
      add :fuel_station, :string
      add :fuel_type, :string, default: "diesel"
      add :notes, :string
      add :vehicle_id, references(:vehicles, on_delete: :nothing)
      add :driver_id, references(:users, on_delete: :nothing)
      add :recorded_by_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:fuel_logs, [:vehicle_id])
    create index(:fuel_logs, [:log_date])
  end
end
