defmodule FleetMint.Repo.Migrations.SplitAdminIntoPlatformAndTenantAdmin do
  use Ecto.Migration

  # The single "admin" role conflated two different authorities: Miway's
  # own platform staff (organisation_id nil) and a tenant's own top-tier
  # staff (organisation_id set). Every admin-gated route treated them
  # identically, so a tenant's "admin" got accidental platform-wide access
  # (all users, the full audit log). Splitting the role string itself,
  # not just checking organisation_id at each call site, so the
  # distinction can never be bypassed by an authorization check that
  # forgets to also check organisation_id.
  def up do
    # Temporarily allow both the old and new values so the backfill below
    # doesn't violate the constraint mid-migration.
    execute "ALTER TABLE users DROP CONSTRAINT users_role_check"

    create constraint(:users, :users_role_check,
             check: "role IN ('admin','manager','cashier','operator','platform_admin','tenant_admin')")

    execute """
    UPDATE users
    SET role = CASE WHEN organisation_id IS NULL THEN 'platform_admin' ELSE 'tenant_admin' END
    WHERE role = 'admin'
    """

    # Retire 'admin' for good now that nothing holds it.
    execute "ALTER TABLE users DROP CONSTRAINT users_role_check"

    create constraint(:users, :users_role_check,
             check: "role IN ('platform_admin','tenant_admin','manager','cashier','operator')")
  end

  def down do
    execute "ALTER TABLE users DROP CONSTRAINT users_role_check"

    create constraint(:users, :users_role_check,
             check: "role IN ('admin','manager','cashier','operator','platform_admin','tenant_admin')")

    execute "UPDATE users SET role = 'admin' WHERE role IN ('platform_admin', 'tenant_admin')"

    execute "ALTER TABLE users DROP CONSTRAINT users_role_check"

    create constraint(:users, :users_role_check,
             check: "role IN ('admin','manager','cashier','operator')")
  end
end
