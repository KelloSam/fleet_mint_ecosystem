defmodule FleetMint.Repo.Migrations.AddMissingForeignKeyIndexes do
  use Ecto.Migration

  def change do
    create index(:bookings, [:booked_by_id])
    create index(:bus_checkpoints, [:reported_by_id])
    create index(:bus_profiles, [:current_route_id])
    create index(:complaints, [:reviewed_by_id])
    create index(:freight_invoices, [:trip_id])
    create index(:freight_invoices, [:created_by_id])
    create index(:freight_orders, [:assigned_trip_id])
    create index(:freight_orders, [:created_by_id])
    create index(:freight_trips, [:driver_id])
    create index(:freight_trips, [:co_driver_id])
    create index(:freight_trips, [:created_by_id])
    create index(:fuel_logs, [:driver_id])
    create index(:fuel_logs, [:recorded_by_id])
    create index(:minibus_trips, [:route_id])
    create index(:schedules, [:driver_id])
    create index(:schedules, [:conductor_id])
    create index(:vehicle_maintenances, [:recorded_by_id])
    create index(:vehicles, [:current_driver_id])
  end
end
