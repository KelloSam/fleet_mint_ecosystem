defmodule FleetMint.Repo.Migrations.CreateOperatorRoutes do
  use Ecto.Migration

  def change do
    create table(:operator_routes, primary_key: false) do
      add :operator_id, references(:operators, on_delete: :delete_all), null: false
      add :route_id,    references(:routes,    on_delete: :delete_all), null: false
    end

    create unique_index(:operator_routes, [:operator_id, :route_id])
    create index(:operator_routes, [:route_id])
  end
end
