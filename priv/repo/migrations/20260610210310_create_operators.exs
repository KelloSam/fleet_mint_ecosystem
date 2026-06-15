defmodule FleetMint.Repo.Migrations.CreateOperators do
  use Ecto.Migration

  def change do
    create table(:operators) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :tagline, :string
      add :contact_phone, :string
      add :contact_email, :string
      add :color, :string, default: "#1d4ed8"
      add :active, :boolean, default: true, null: false
      timestamps()
    end

    create unique_index(:operators, [:slug])
    create unique_index(:operators, [:name])
    create index(:operators, [:active])
  end
end
