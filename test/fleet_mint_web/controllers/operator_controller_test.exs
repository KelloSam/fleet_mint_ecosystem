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
end
