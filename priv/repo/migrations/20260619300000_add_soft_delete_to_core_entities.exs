defmodule FleetMint.Repo.Migrations.AddSoftDeleteToCoreEntities do
  use Ecto.Migration

  def change do
    for table <- [:vehicles, :drivers, :routes, :operators] do
      alter table(table) do
        add :archived_at, :naive_datetime, null: true
      end

      create index(table, [:archived_at])
    end
  end
end
