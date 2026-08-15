defmodule FleetMintWeb.BranchControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant isolation" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      branch_a = branch_fixture(organisation_id: org_a.organisation_id)
      branch_b = branch_fixture(organisation_id: org_b.organisation_id)

      tenant_user = user_fixture(organisation_id: org_a.organisation_id)
      platform_user = user_fixture(organisation_id: nil)

      %{
        org_a: org_a,
        branch_a: branch_a,
        branch_b: branch_b,
        tenant_user: tenant_user,
        platform_user: platform_user
      }
    end

    test "authorised: tenant user can view their own organisation's branch", %{
      conn: conn,
      tenant_user: tenant_user,
      branch_a: branch_a
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/branches/#{branch_a}")
      assert html_response(conn, 200) =~ branch_a.name
    end

    test "prohibited: tenant user cannot view another organisation's branch", %{
      conn: conn,
      tenant_user: tenant_user,
      branch_b: branch_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/branches/#{branch_b}")
      assert redirected_to(conn) == ~p"/branches"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: tenant user cannot edit another organisation's branch", %{
      conn: conn,
      tenant_user: tenant_user,
      branch_b: branch_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/branches/#{branch_b}/edit")
      assert redirected_to(conn) == ~p"/branches"
    end

    test "prohibited: tenant user cannot update another organisation's branch", %{
      conn: conn,
      tenant_user: tenant_user,
      branch_b: branch_b
    } do
      conn =
        conn
        |> log_in_user(tenant_user)
        |> put(~p"/branches/#{branch_b}", %{"branch" => %{"city" => "Tampered"}})

      assert redirected_to(conn) == ~p"/branches"
      reloaded = FleetMint.Transport.Fleet.get_branch!(branch_b.id)
      assert reloaded.city != "Tampered"
    end

    test "prohibited: tenant user cannot delete another organisation's branch", %{
      conn: conn,
      tenant_user: tenant_user,
      branch_b: branch_b
    } do
      conn = conn |> log_in_user(tenant_user) |> delete(~p"/branches/#{branch_b}")
      assert redirected_to(conn) == ~p"/branches"
      assert FleetMint.Transport.Fleet.get_branch!(branch_b.id)
    end

    test "authorised: platform-level user can view any organisation's branch", %{
      conn: conn,
      platform_user: platform_user,
      branch_a: branch_a,
      branch_b: branch_b
    } do
      conn_a = conn |> log_in_user(platform_user) |> get(~p"/branches/#{branch_a}")
      assert html_response(conn_a, 200) =~ branch_a.name

      conn_b = conn |> log_in_user(platform_user) |> get(~p"/branches/#{branch_b}")
      assert html_response(conn_b, 200) =~ branch_b.name
    end

    test "authorised: tenant user's index only lists their own organisation's branches", %{
      conn: conn,
      tenant_user: tenant_user,
      branch_a: branch_a,
      branch_b: branch_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/branches")
      html = html_response(conn, 200)

      assert html =~ branch_a.name
      refute html =~ branch_b.name
    end

    test "authorised: creating a branch forces the tenant's own organisation regardless of submitted value",
         %{
           conn: conn,
           tenant_user: tenant_user,
           org_a: org_a
         } do
      other_org = operator_fixture()

      conn =
        conn
        |> log_in_user(tenant_user)
        |> post(~p"/branches", %{
          "branch" => %{
            "name" => "Tamper Branch",
            "organisation_id" => other_org.organisation_id
          }
        })

      branches = FleetMint.Transport.Fleet.list_branches(org_a.organisation_id)
      branch = Enum.find(branches, &(&1.name == "Tamper Branch"))
      assert redirected_to(conn) == ~p"/branches/#{branch}"
      assert branch.organisation_id == org_a.organisation_id
    end
  end
end
