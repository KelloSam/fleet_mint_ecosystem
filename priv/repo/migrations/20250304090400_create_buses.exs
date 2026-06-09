defmodule FleetMint.Repo.Migrations.CreateBuses do
  use Ecto.Migration

  def change do
    create table(:buses) do
      add :number, :string
      add :capacity, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
