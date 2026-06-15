defmodule FleetMint.Repo.Migrations.CreateBusCheckpoints do
  use Ecto.Migration

  def change do
    create table(:bus_checkpoints) do
      add :schedule_id, references(:schedules, on_delete: :delete_all), null: false
      add :travel_date, :date, null: false
      add :location, :string, null: false
      add :notes, :string
      add :reported_by_id, references(:users, on_delete: :nilify_all)
      timestamps(updated_at: false)
    end

    create index(:bus_checkpoints, [:schedule_id, :travel_date])
    create index(:bus_checkpoints, [:inserted_at])
  end
end
