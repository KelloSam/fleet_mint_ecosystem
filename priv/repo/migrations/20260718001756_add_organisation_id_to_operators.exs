defmodule FleetMint.Repo.Migrations.AddOrganisationIdToOperators do
  use Ecto.Migration

  def up do
    alter table(:operators) do
      add :organisation_id, references(:organisations)
    end

    # Every existing operator is today's whole tenant (it predates the
    # Organisation/Operator split) — give each one its own Organisation,
    # matched back up by the slug they already have.
    execute """
    INSERT INTO organisations (name, slug, active, inserted_at, updated_at)
    SELECT name, slug, active, now(), now() FROM operators
    """

    execute """
    UPDATE operators o
    SET organisation_id = g.id
    FROM organisations g
    WHERE g.slug = o.slug
    """

    alter table(:operators) do
      modify :organisation_id, :bigint, null: false
    end

    create index(:operators, [:organisation_id])
  end

  def down do
    drop index(:operators, [:organisation_id])

    alter table(:operators) do
      remove :organisation_id
    end
  end
end
