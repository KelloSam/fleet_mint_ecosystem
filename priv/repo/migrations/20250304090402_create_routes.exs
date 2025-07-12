defmodule BusCashingSystem.Repo.Migrations.CreateRoutes do
  use Ecto.Migration

  def change do
    create table(:routes) do
      add :name, :string
      add :start_point, :string
      add :end_point, :string

      timestamps(type: :utc_datetime)
    end
  end
end
