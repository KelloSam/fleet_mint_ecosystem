defmodule FleetMint.Repo.Migrations.CreateDrivers do
  use Ecto.Migration

  def change do
    create table(:drivers) do
      add :name, :string, null: false
      add :phone, :string
      add :license_number, :string
      add :license_expiry, :date
      add :daily_rate, :decimal, precision: 10, scale: 2
      add :date_hired, :date
      add :status, :string, default: "active"
      add :notes, :text
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    create index(:drivers, [:status])
    create index(:drivers, [:user_id])
    create unique_index(:drivers, [:license_number])
  end
end
