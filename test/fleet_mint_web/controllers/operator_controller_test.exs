defmodule FleetMintWeb.OperatorControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "platform-only tenant onboarding" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      platform_admin = user_fixture(organisation_id: nil)
      tenant_admin_a = user_fixture(role: "tenant_admin", organisation_id: org_a.organisation_id)
      manager_a = user_fixture(role: "manager", organisation_id: org_a.organisation_id)

      %{org_a: org_a, org_b: org_b, platform_admin: platform_admin, tenant_admin_a: tenant_admin_a, manager_a: manager_a}
    end

    test "prohibited: a tenant_admin cannot create a new operator (onboard a new tenant)", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a
    } do
      conn =
        conn
        |> log_in_user(tenant_admin_a)
        |> post(~p"/operators", %{"operator" => %{"name" => "New Tenant Co", "slug" => "new-tenant-co"}})

      assert redirected_to(conn) == ~p"/operators"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "platform administrators"
      refute FleetMint.Repo.get_by(FleetMint.Transport.Fleet.Operator, slug: "new-tenant-co")
    end

    test "prohibited: a manager cannot create a new operator either", %{conn: conn, manager_a: manager_a} do
      conn =
        conn
        |> log_in_user(manager_a)
        |> post(~p"/operators", %{"operator" => %{"name" => "New Tenant Co", "slug" => "new-tenant-co-2"}})

      assert redirected_to(conn) == ~p"/operators"
    end

    test "authorised: a platform_admin can create a new operator", %{conn: conn, platform_admin: platform_admin} do
      conn =
        conn
        |> log_in_user(platform_admin)
        |> post(~p"/operators", %{"operator" => %{"name" => "New Tenant Co", "slug" => "new-tenant-co-3"}})

      operator = FleetMint.Repo.get_by(FleetMint.Transport.Fleet.Operator, slug: "new-tenant-co-3")
      assert redirected_to(conn) == ~p"/operators"
      assert operator
      assert operator.organisation_id
    end

    test "prohibited: a tenant_admin cannot edit another organisation's operator profile", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      org_b: org_b
    } do
      conn =
        conn
        |> log_in_user(tenant_admin_a)
        |> put(~p"/operators/#{org_b}", %{"operator" => %{"name" => "Tampered Name"}})

      assert redirected_to(conn) == ~p"/operators"

      reloaded = FleetMint.Transport.Fleet.get_operator!(org_b.id)
      assert reloaded.name == org_b.name
    end

    test "authorised: a tenant_admin can edit their own operator profile", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      org_a: org_a
    } do
      conn =
        conn
        |> log_in_user(tenant_admin_a)
        |> put(~p"/operators/#{org_a}", %{"operator" => %{"name" => "Updated Name"}})

      assert redirected_to(conn) == ~p"/operators"
      reloaded = FleetMint.Transport.Fleet.get_operator!(org_a.id)
      assert reloaded.name == "Updated Name"
    end

    test "authorised: index only lists the caller's own organisation's operator for tenant staff", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      org_a: org_a,
      org_b: org_b
    } do
      conn = conn |> log_in_user(tenant_admin_a) |> get(~p"/operators")
      html = html_response(conn, 200)

      assert html =~ org_a.name
      refute html =~ org_b.name
    end
  end

  describe "audit logging" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      platform_admin = user_fixture(organisation_id: nil)
      tenant_admin_a = user_fixture(role: "tenant_admin", organisation_id: org_a.organisation_id)

      %{org_a: org_a, org_b: org_b, platform_admin: platform_admin, tenant_admin_a: tenant_admin_a}
    end

    test "operator_created is logged with the new organisation", %{conn: conn, platform_admin: platform_admin} do
      conn
      |> log_in_user(platform_admin)
      |> post(~p"/operators", %{"operator" => %{"name" => "Audited Co", "slug" => "audited-co"}})

      operator = FleetMint.Repo.get_by(FleetMint.Transport.Fleet.Operator, slug: "audited-co")

      [log] =
        FleetMint.Administration.list_recent_audit_logs(10)
        |> Enum.filter(&(&1.event == "operator_created" and &1.target_id == to_string(operator.id)))

      assert log.actor_id == platform_admin.id
      assert log.metadata["name"] == "Audited Co"
    end

    test "platform_only_action_denied is logged when a tenant_admin attempts to create an operator", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a
    } do
      conn
      |> log_in_user(tenant_admin_a)
      |> post(~p"/operators", %{"operator" => %{"name" => "Blocked Co", "slug" => "blocked-co"}})

      [log] = FleetMint.Administration.list_recent_audit_logs(10) |> Enum.filter(&(&1.event == "platform_only_action_denied"))
      assert log.actor_id == tenant_admin_a.id
    end

    test "cross_tenant_access_denied is logged when a tenant_admin is blocked from another organisation's operator", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      org_b: org_b
    } do
      conn |> log_in_user(tenant_admin_a) |> put(~p"/operators/#{org_b}", %{"operator" => %{"name" => "Tampered"}})

      [log] =
        FleetMint.Administration.list_recent_audit_logs(10)
        |> Enum.filter(&(&1.event == "cross_tenant_access_denied" and &1.target_id == to_string(org_b.id)))

      assert log.actor_id == tenant_admin_a.id
    end

    test "operator_archived is logged", %{conn: conn, platform_admin: platform_admin, org_a: org_a} do
      conn |> log_in_user(platform_admin) |> delete(~p"/operators/#{org_a}")

      [log] =
        FleetMint.Administration.list_recent_audit_logs(10)
        |> Enum.filter(&(&1.event == "operator_archived" and &1.target_id == to_string(org_a.id)))

      assert log.actor_id == platform_admin.id
    end
  end
end
