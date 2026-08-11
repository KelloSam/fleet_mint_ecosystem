defmodule FleetMintWeb.ApiControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures
  import FleetMint.TicketingFixtures

  describe "GET /api/notifications" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      schedule_a = schedule_fixture(operator_id: org_a.id)
      schedule_b = schedule_fixture(operator_id: org_b.id)

      booking_a = booking_fixture(schedule: schedule_a)
      booking_b = booking_fixture(schedule: schedule_b)

      manager_a = user_fixture(role: "manager", organisation_id: org_a.organisation_id)
      tenant_admin_a = user_fixture(role: "tenant_admin", organisation_id: org_a.organisation_id)
      platform_admin = user_fixture(organisation_id: nil)
      cashier_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)

      since =
        NaiveDateTime.add(NaiveDateTime.utc_now(), -3600, :second) |> NaiveDateTime.to_iso8601()

      %{
        booking_a: booking_a,
        booking_b: booking_b,
        manager_a: manager_a,
        tenant_admin_a: tenant_admin_a,
        platform_admin: platform_admin,
        cashier_a: cashier_a,
        since: since
      }
    end

    test "only returns the caller's own organisation's bookings", %{
      conn: conn,
      manager_a: manager_a,
      booking_a: booking_a,
      booking_b: booking_b,
      since: since
    } do
      conn = conn |> log_in_user(manager_a) |> get(~p"/api/notifications?since=#{since}")
      %{"bookings" => bookings} = json_response(conn, 200)
      refs = Enum.map(bookings, & &1["reference"])

      assert booking_a.booking_reference in refs
      refute booking_b.booking_reference in refs
    end

    test "platform_admin sees bookings across every organisation", %{
      conn: conn,
      platform_admin: platform_admin,
      booking_a: booking_a,
      booking_b: booking_b,
      since: since
    } do
      conn = conn |> log_in_user(platform_admin) |> get(~p"/api/notifications?since=#{since}")
      %{"bookings" => bookings} = json_response(conn, 200)
      refs = Enum.map(bookings, & &1["reference"])

      assert booking_a.booking_reference in refs
      assert booking_b.booking_reference in refs
    end

    test "tenant_admin is allowed (was locked out under the old \"admin\" role check)", %{
      conn: conn,
      tenant_admin_a: tenant_admin_a,
      since: since
    } do
      conn = conn |> log_in_user(tenant_admin_a) |> get(~p"/api/notifications?since=#{since}")
      assert %{"bookings" => _} = json_response(conn, 200)
    end

    test "cashier is forbidden", %{conn: conn, cashier_a: cashier_a, since: since} do
      conn = conn |> log_in_user(cashier_a) |> get(~p"/api/notifications?since=#{since}")
      assert json_response(conn, 403)
    end
  end
end
