defmodule FleetMint.Repo.Migrations.AddSeatLabelsToBusProfiles do
  use Ecto.Migration

  def change do
    alter table(:bus_profiles) do
      add :seat_labels, {:array, :string}, default: []
    end
  end
end
