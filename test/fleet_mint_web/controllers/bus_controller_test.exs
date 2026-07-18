defmodule FleetMintWeb.BusControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "tenant isolation" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(organisation_id: org_a.organisation_id)
      bus_b = bus_fixture(organisation_id: org_b.organisation_id)

      tenant_user = user_fixture(organisation_id: org_a.organisation_id)
      platform_user = user_fixture(organisation_id: nil)

      %{
        org_a: org_a,
        bus_a: bus_a,
        bus_b: bus_b,
        tenant_user: tenant_user,
        platform_user: platform_user
      }
    end

    test "authorised: tenant user can view their own organisation's bus", %{
      conn: conn,
      tenant_user: tenant_user,
      bus_a: bus_a
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/buses/#{bus_a}")
      assert html_response(conn, 200) =~ bus_a.registration_number
    end

    test "prohibited: tenant user cannot view another organisation's bus", %{
      conn: conn,
      tenant_user: tenant_user,
      bus_b: bus_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/buses/#{bus_b}")
      assert redirected_to(conn) == ~p"/buses"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: tenant user cannot edit another organisation's bus", %{
      conn: conn,
      tenant_user: tenant_user,
      bus_b: bus_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/buses/#{bus_b}/edit")
      assert redirected_to(conn) == ~p"/buses"
    end

    test "prohibited: tenant user cannot update another organisation's bus", %{
      conn: conn,
      tenant_user: tenant_user,
      bus_b: bus_b
    } do
      conn =
        conn
        |> log_in_user(tenant_user)
        |> put(~p"/buses/#{bus_b}", %{"bus" => %{"status" => "inactive"}})

      assert redirected_to(conn) == ~p"/buses"
      assert bus_b.status == "active"
      reloaded = FleetMint.Transport.Fleet.get_bus!(bus_b.id)
      assert reloaded.status == "active"
    end

    test "prohibited: tenant user cannot delete another organisation's bus", %{
      conn: conn,
      tenant_user: tenant_user,
      bus_b: bus_b
    } do
      conn = conn |> log_in_user(tenant_user) |> delete(~p"/buses/#{bus_b}")
      assert redirected_to(conn) == ~p"/buses"
      assert FleetMint.Transport.Fleet.get_bus!(bus_b.id)
    end

    test "authorised: platform-level user can view any organisation's bus", %{
      conn: conn,
      platform_user: platform_user,
      bus_a: bus_a,
      bus_b: bus_b
    } do
      conn_a = conn |> log_in_user(platform_user) |> get(~p"/buses/#{bus_a}")
      assert html_response(conn_a, 200) =~ bus_a.registration_number

      conn_b = conn |> log_in_user(platform_user) |> get(~p"/buses/#{bus_b}")
      assert html_response(conn_b, 200) =~ bus_b.registration_number
    end

    test "authorised: tenant user's index only lists their own organisation's buses", %{
      conn: conn,
      tenant_user: tenant_user,
      bus_a: bus_a,
      bus_b: bus_b
    } do
      conn = conn |> log_in_user(tenant_user) |> get(~p"/buses")
      html = html_response(conn, 200)

      assert html =~ bus_a.registration_number
      refute html =~ bus_b.registration_number
    end

    test "authorised: creating a bus forces the tenant's own organisation regardless of submitted value", %{
      conn: conn,
      tenant_user: tenant_user,
      org_a: org_a
    } do
      other_org = operator_fixture()

      conn =
        conn
        |> log_in_user(tenant_user)
        |> post(~p"/buses", %{
          "bus" => %{
            "registration_number" => "TAMPER1",
            "capacity" => "60",
            "model" => "Yutong",
            "year" => "2022",
            "status" => "active",
            "organisation_id" => other_org.organisation_id
          }
        })

      bus = FleetMint.Transport.Fleet.get_bus_by_registration_number("TAMPER1")
      assert redirected_to(conn) == ~p"/buses/#{bus}"
      assert bus.organisation_id == org_a.organisation_id
    end
  end
end
