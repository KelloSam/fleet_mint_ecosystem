defmodule FleetMint.Repo.Migrations.CreateMinibusTrips do
  use Ecto.Migration

  def change do
    create table(:minibus_trips) do
      add :date, :date, null: false
      add :status, :string, default: "scheduled"
      add :passengers_count, :integer, default: 0
      add :fare_collected, :decimal, default: 0
      add :fuel_cost, :decimal, default: 0
      add :notes, :string
      add :bus_id, references(:buses, on_delete: :nothing)
      add :route_id, references(:routes, on_delete: :nothing)
      add :driver_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:minibus_trips, [:date])
    create index(:minibus_trips, [:bus_id])
    create index(:minibus_trips, [:driver_id])
  end
end
