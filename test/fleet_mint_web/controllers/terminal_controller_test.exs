defmodule FleetMintWeb.TerminalControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant isolation" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      branch_a = branch_fixture(organisation_id: org_a.organisation_id)
      branch_b = branch_fixture(organisation_id: org_b.organisation_id)

      terminal_a = terminal_fixture(branch: branch_a)
      terminal_b = terminal_fixture(branch: branch_b)

      tenant_user = user_fixture(organisation_id: org_a.organisation_id)
      platform_user = user_fixture(organisation_id: nil)

      %{
        org_a: org_a,
        branch_a: branch_a,
        branch_b: branch_b,
        terminal_a: terminal_a,
        terminal_b: terminal_b,
        tenant_user: tenant_user,
        platform_user: platform_user
      }
    end

    test "authorised: tenant user can view their own organisation's terminal", %{
      conn: conn,
      tenant_user: tenant_user,
      terminal_a: terminal_a
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/terminals/#{terminal_a}")
      assert html_response(conn, 200) =~ terminal_a.name
    end

    test "prohibited: tenant user cannot view another organisation's terminal", %{
      conn: conn,
      tenant_user: tenant_user,
      terminal_b: terminal_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/terminals/#{terminal_b}")
      assert redirected_to(conn) == ~p"/terminals"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: tenant user cannot edit another organisation's terminal", %{
      conn: conn,
      tenant_user: tenant_user,
      terminal_b: terminal_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/terminals/#{terminal_b}/edit")
      assert redirected_to(conn) == ~p"/terminals"
    end

    test "prohibited: tenant user cannot update another organisation's terminal", %{
      conn: conn,
      tenant_user: tenant_user,
      terminal_b: terminal_b
    } do
      conn =
        conn
        |> log_in_user(tenant_user)
        |> put(~p"/terminals/#{terminal_b}", %{"terminal" => %{"address" => "Tampered"}})

      assert redirected_to(conn) == ~p"/terminals"
      reloaded = FleetMint.Transport.Fleet.get_terminal!(terminal_b.id)
      assert reloaded.address != "Tampered"
    end

    test "prohibited: tenant user cannot delete another organisation's terminal", %{
      conn: conn,
      tenant_user: tenant_user,
      terminal_b: terminal_b
    } do
      conn = conn |> log_in_user(tenant_user) |> delete(~p"/terminals/#{terminal_b}")
      assert redirected_to(conn) == ~p"/terminals"
      assert FleetMint.Transport.Fleet.get_terminal!(terminal_b.id)
    end

    test "authorised: platform-level user can view any organisation's terminal", %{
      conn: conn,
      platform_user: platform_user,
      terminal_a: terminal_a,
      terminal_b: terminal_b
    } do
      conn_a = conn |> log_in_user(platform_user) |> get(~p"/terminals/#{terminal_a}")
      assert html_response(conn_a, 200) =~ terminal_a.name

      conn_b = conn |> log_in_user(platform_user) |> get(~p"/terminals/#{terminal_b}")
      assert html_response(conn_b, 200) =~ terminal_b.name
    end

    test "authorised: tenant user's index only lists their own organisation's terminals", %{
      conn: conn,
      tenant_user: tenant_user,
      terminal_a: terminal_a,
      terminal_b: terminal_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/terminals")
      html = html_response(conn, 200)

      assert html =~ terminal_a.name
      refute html =~ terminal_b.name
    end

    test "prohibited: tenant user cannot create a terminal under another organisation's branch",
         %{
           conn: conn,
           tenant_user: tenant_user,
           branch_b: branch_b
         } do
      conn =
        conn
        |> log_in_user(tenant_user)
        |> post(~p"/terminals", %{
          "terminal" => %{"name" => "Tamper Terminal", "branch_id" => branch_b.id}
        })

      assert html_response(conn, 200) =~ "not available to you"

      refute FleetMint.Transport.Fleet.list_terminals(:all)
             |> Enum.any?(&(&1.name == "Tamper Terminal"))
    end

    test "authorised: tenant user can create a terminal under their own organisation's branch",
         %{
           conn: conn,
           tenant_user: tenant_user,
           branch_a: branch_a
         } do
      conn =
        conn
        |> log_in_user(tenant_user)
        |> post(~p"/terminals", %{
          "terminal" => %{"name" => "New Terminal", "branch_id" => branch_a.id}
        })

      terminal =
        FleetMint.Transport.Fleet.list_terminals(:all) |> Enum.find(&(&1.name == "New Terminal"))

      assert redirected_to(conn) == ~p"/terminals/#{terminal}"
      assert terminal.branch_id == branch_a.id
    end
  end
end
