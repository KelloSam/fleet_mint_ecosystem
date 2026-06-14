defmodule FleetMint.Repo.Migrations.AddLuggageToBookings do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :has_luggage, :boolean, default: false, null: false
      add :luggage_description, :string
    end
  end
end
