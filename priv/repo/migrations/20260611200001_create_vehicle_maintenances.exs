defmodule FleetMint.Repo.Migrations.CreateVehicleMaintenances do
  use Ecto.Migration

  def change do
    create table(:vehicle_maintenances) do
      add :service_date, :date, null: false
      add :service_type, :string, null: false
      add :description, :string
      add :cost, :decimal
      add :mileage_at_service, :integer
      add :next_service_date, :date
      add :next_service_mileage, :integer
      add :garage, :string
      add :status, :string, default: "completed"
      add :vehicle_id, references(:vehicles, on_delete: :nothing)
      add :recorded_by_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:vehicle_maintenances, [:vehicle_id])
    create index(:vehicle_maintenances, [:service_date])
  end
end
