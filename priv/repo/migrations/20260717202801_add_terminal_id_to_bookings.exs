defmodule FleetMint.Repo.Migrations.AddTerminalIdToBookings do
  use Ecto.Migration

  def up do
    alter table(:bookings) do
      # Structured replacement for the free-text `pickup_station`. Nullable
      # for now — existing bookings and operators without terminal data yet
      # keep working off the text field until it's populated.
      add :terminal_id, references(:terminals, on_delete: :nilify_all)
    end

    create index(:bookings, [:terminal_id])
  end

  def down do
    drop index(:bookings, [:terminal_id])

    alter table(:bookings) do
      remove :terminal_id
    end
  end
end
