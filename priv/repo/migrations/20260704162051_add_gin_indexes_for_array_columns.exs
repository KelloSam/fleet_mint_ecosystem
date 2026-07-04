defmodule FleetMint.Repo.Migrations.AddGinIndexesForArrayColumns do
  use Ecto.Migration

  def change do
    create index(:routes, [:stops], using: :gin)
    create index(:schedules, [:days_of_week], using: :gin)
    create index(:bus_profiles, [:amenities], using: :gin)
    create index(:bus_profiles, [:seat_labels], using: :gin)
    create index(:truck_profiles, [:allowed_cargo_types], using: :gin)
  end
end
