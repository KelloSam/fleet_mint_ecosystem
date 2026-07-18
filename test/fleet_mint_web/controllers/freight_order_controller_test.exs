defmodule FleetMintWeb.FreightOrderControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.CargoFixtures
  import FleetMint.IdentityFixtures

  alias FleetMint.Cargo
  alias FleetMint.FleetFixtures

  # No FreightOrderController test suite existed before this - only the
  # context-level tenant-scoping tests in cargo_test.exs. Scoped here to
  # proving the new order/trip assignment safety check (Phase 5) actually
  # holds through a real HTTP request, not backfilling full CRUD coverage
  # for this controller (a pre-existing gap, named rather than silently
  # left implicit - see docs/phase5_cargo_lifecycle_checkpoint.md).
  describe "order/trip assignment safety via a real request" do
    setup do
      org_a = FleetFixtures.operator_fixture()
      org_b = FleetFixtures.operator_fixture()

      admin_a = user_fixture(role: "tenant_admin", organisation_id: org_a.organisation_id)
      client_a = client_fixture(organisation_id: org_a.organisation_id)
      order = order_fixture(client: client_a, weight_tons: "1.0")

      trip_b = trip_fixture(vehicle: FleetFixtures.vehicle_fixture(%{"organisation_id" => org_b.organisation_id}))

      %{admin_a: admin_a, order: order, trip_b: trip_b}
    end

    test "a tampered cross-organisation assigned_trip_id is rejected and the order stays unassigned", %{
      conn: conn,
      admin_a: admin_a,
      order: order,
      trip_b: trip_b
    } do
      conn =
        conn
        |> log_in_user(admin_a)
        |> put(~p"/freight/orders/#{order}", %{"order" => %{"assigned_trip_id" => trip_b.id}})

      assert html_response(conn, 200) =~ "different organisation"

      reloaded = Cargo.get_order!(order.id)
      assert reloaded.assigned_trip_id == nil
    end
  end
end
