defmodule FleetMint.Repo.Migrations.LinkBusesToVehiclesAndRepointDrivers do
  use Ecto.Migration

  def change do
    # --- Fix 1: bridge the legacy `buses` table to the new `vehicles` model ---
    alter table(:buses) do
      add :vehicle_id, references(:vehicles, on_delete: :nilify_all)
    end

    create index(:buses, [:vehicle_id])

    # --- Fix 2: repoint driver-assignment columns at `drivers`, not `users` ---
    drop constraint(:schedules, "schedules_driver_id_fkey")

    alter table(:schedules) do
      modify :driver_id, references(:drivers, on_delete: :nilify_all)
    end

    drop constraint(:freight_trips, "freight_trips_driver_id_fkey")
    drop constraint(:freight_trips, "freight_trips_co_driver_id_fkey")

    alter table(:freight_trips) do
      modify :driver_id, references(:drivers, on_delete: :nilify_all)
      modify :co_driver_id, references(:drivers, on_delete: :nilify_all)
    end

    drop constraint(:vehicles, "vehicles_current_driver_id_fkey")

    alter table(:vehicles) do
      modify :current_driver_id, references(:drivers, on_delete: :nilify_all)
    end

    drop constraint(:fuel_logs, "fuel_logs_driver_id_fkey")

    alter table(:fuel_logs) do
      modify :driver_id, references(:drivers, on_delete: :nilify_all)
    end

    drop constraint(:minibus_trips, "minibus_trips_driver_id_fkey")

    alter table(:minibus_trips) do
      modify :driver_id, references(:drivers, on_delete: :nilify_all)
    end
  end
end
