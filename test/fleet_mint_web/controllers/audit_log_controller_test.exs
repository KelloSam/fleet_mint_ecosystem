defmodule FleetMintWeb.AuditLogControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.IdentityFixtures

  describe "platform-only audit trail" do
    test "prohibited: a tenant_admin cannot reach /audit-log", %{conn: conn} do
      org = operator_fixture()
      tenant_admin = user_fixture(role: "tenant_admin", organisation_id: org.organisation_id)

      conn = conn |> log_in_user(tenant_admin) |> get(~p"/audit-log")

      assert redirected_to(conn) == ~p"/dashboard"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "don't have permission"
    end

    test "authorised: a platform_admin can reach /audit-log", %{conn: conn} do
      platform_admin = user_fixture(organisation_id: nil)

      conn = conn |> log_in_user(platform_admin) |> get(~p"/audit-log")

      assert html_response(conn, 200) =~ "Audit"
    end
  end

  describe "Administration.log/2 stamps organisation_id from the actor" do
    test "derives organisation_id from the actor's own organisation" do
      org = operator_fixture()
      staff = user_fixture(role: "cashier", organisation_id: org.organisation_id)

      :ok = FleetMint.Administration.log("test_event", actor_id: staff.id, actor_email: staff.email)

      [log] = FleetMint.Administration.list_recent_audit_logs(1)
      assert log.organisation_id == org.organisation_id
    end

    test "stays platform-only (nil) when there is no known actor" do
      :ok = FleetMint.Administration.log("login_failure", actor_email: "unknown@example.com")

      [log] = FleetMint.Administration.list_recent_audit_logs(1)
      assert log.organisation_id == nil
    end

    test "list_recent_audit_logs/2 with an organisation_id only returns that organisation's events" do
      org_a = operator_fixture()
      org_b = operator_fixture()
      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)
      staff_b = user_fixture(role: "cashier", organisation_id: org_b.organisation_id)

      :ok = FleetMint.Administration.log("scoped_event_a", actor_id: staff_a.id)
      :ok = FleetMint.Administration.log("scoped_event_b", actor_id: staff_b.id)

      events = FleetMint.Administration.list_recent_audit_logs(50, organisation_id: org_a.organisation_id)
      assert Enum.any?(events, &(&1.event == "scoped_event_a"))
      refute Enum.any?(events, &(&1.event == "scoped_event_b"))
    end
  end
end
