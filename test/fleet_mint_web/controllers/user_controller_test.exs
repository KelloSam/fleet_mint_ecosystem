defmodule FleetMintWeb.UserControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  alias FleetMint.Identity.Users

  describe "tenant vs platform administration" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      platform_admin = user_fixture(organisation_id: nil)
      tenant_admin_a = user_fixture(role: "tenant_admin", organisation_id: org_a.organisation_id)
      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)
      staff_b = user_fixture(role: "cashier", organisation_id: org_b.organisation_id)
      manager_a = user_fixture(role: "manager", organisation_id: org_a.organisation_id)

      %{
        org_a: org_a,
        org_b: org_b,
        platform_admin: platform_admin,
        tenant_admin_a: tenant_admin_a,
        staff_a: staff_a,
        staff_b: staff_b,
        manager_a: manager_a
      }
    end

    test "prohibited: a manager (not an admin tier) cannot reach /users at all", %{conn: conn, manager_a: manager_a} do
      conn = conn |> log_in_user(manager_a) |> get(~p"/users")
      assert redirected_to(conn) == ~p"/dashboard"
    end

    test "authorised: a tenant_admin's index lists only their own organisation's users", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      staff_a: staff_a,
      staff_b: staff_b
    } do
      conn = conn |> log_in_user(tenant_admin_a) |> get(~p"/users")
      html = html_response(conn, 200)

      assert html =~ staff_a.email
      refute html =~ staff_b.email
    end

    test "authorised: a platform_admin's index lists every organisation's users", %{
      conn: conn,
      platform_admin: platform_admin,
      staff_a: staff_a,
      staff_b: staff_b
    } do
      conn = conn |> log_in_user(platform_admin) |> get(~p"/users")
      html = html_response(conn, 200)

      assert html =~ staff_a.email
      assert html =~ staff_b.email
    end

    test "prohibited: a tenant_admin cannot view another organisation's user", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      staff_b: staff_b
    } do
      conn = conn |> log_in_user(tenant_admin_a) |> get(~p"/users/#{staff_b}")
      assert redirected_to(conn) == ~p"/users"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: a tenant_admin cannot edit or deactivate another organisation's user", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      staff_b: staff_b
    } do
      conn = conn |> log_in_user(tenant_admin_a) |> post(~p"/users/#{staff_b}/deactivate")
      assert redirected_to(conn) == ~p"/users"

      reloaded = Users.get_user!(staff_b.id)
      assert reloaded.active == staff_b.active
    end

    test "authorised: a tenant_admin creating a user forces their own organisation regardless of submitted value", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      org_a: org_a,
      org_b: org_b
    } do
      conn =
        conn
        |> log_in_user(tenant_admin_a)
        |> post(~p"/users", %{
          "user" => %{
            "username" => "tampered_user",
            "email" => "tampered@example.com",
            "password" => "Password123!secure",
            "full_name" => "Tampered User",
            "role" => "cashier",
            "active" => "true",
            "organisation_id" => org_b.organisation_id
          }
        })

      user = Users.get_user_by_username("tampered_user")
      assert redirected_to(conn) == ~p"/users/#{user}"
      assert user.organisation_id == org_a.organisation_id
    end

    test "prohibited: a tenant_admin cannot grant platform_admin to a new user", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a
    } do
      conn =
        conn
        |> log_in_user(tenant_admin_a)
        |> post(~p"/users", %{
          "user" => %{
            "username" => "escalated_user",
            "email" => "escalated@example.com",
            "password" => "Password123!secure",
            "full_name" => "Escalated User",
            "role" => "platform_admin",
            "active" => "true"
          }
        })

      user = Users.get_user_by_username("escalated_user")
      assert redirected_to(conn) == ~p"/users/#{user}"
      assert user.role == "tenant_admin"
    end

    test "prohibited: a tenant_admin cannot escalate an existing user to platform_admin via update", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      staff_a: staff_a
    } do
      conn =
        conn
        |> log_in_user(tenant_admin_a)
        |> put(~p"/users/#{staff_a}", %{
          "user" => %{"role" => "platform_admin", "active" => "true"}
        })

      assert redirected_to(conn) == ~p"/users/#{staff_a}"

      reloaded = Users.get_user!(staff_a.id)
      assert reloaded.role == "tenant_admin"
      assert reloaded.organisation_id == staff_a.organisation_id
    end

    test "authorised: a platform_admin can create a user in any organisation with any role", %{
      conn: conn,
      platform_admin: platform_admin,
      org_b: org_b
    } do
      conn =
        conn
        |> log_in_user(platform_admin)
        |> post(~p"/users", %{
          "user" => %{
            "username" => "platform_created",
            "email" => "platform_created@example.com",
            "password" => "Password123!secure",
            "full_name" => "Platform Created",
            "role" => "tenant_admin",
            "active" => "true",
            "organisation_id" => org_b.organisation_id
          }
        })

      user = Users.get_user_by_username("platform_created")
      assert redirected_to(conn) == ~p"/users/#{user}"
      assert user.organisation_id == org_b.organisation_id
      assert user.role == "tenant_admin"
    end
  end
end
