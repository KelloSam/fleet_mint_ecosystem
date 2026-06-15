defmodule FleetMint.Repo.Migrations.AddPickupStationToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :pickup_station, :string
    end
  end
end
