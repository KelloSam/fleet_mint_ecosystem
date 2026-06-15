defmodule FleetMint.Repo.Migrations.AddStopsToRoutes do
  use Ecto.Migration

  def change do
    alter table(:routes) do
      add :stops, {:array, :string}, default: []
    end
  end
end
