defmodule FleetMint.Repo.Migrations.AddPasswordResetToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :reset_token_hash,       :string
      add :reset_token_expires_at, :naive_datetime
    end
  end
end
