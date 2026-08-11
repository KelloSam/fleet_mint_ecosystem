defmodule FleetMintWeb.PublicBookingControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.TicketingFixtures
  import FleetMint.FleetFixtures

  describe "operator/schedule mismatch protection" do
    test "book/2 404s when the schedule doesn't belong to the operator in the URL" do
      org_a = operator_fixture()
      org_b = operator_fixture()
      schedule_b = schedule_fixture(operator_id: org_b.id)

      assert_error_sent 404, fn ->
        get(build_conn(), ~p"/book/#{org_a.slug}/#{schedule_b.id}")
      end
    end

    test "create/2 404s when the schedule doesn't belong to the operator in the URL" do
      org_a = operator_fixture()
      org_b = operator_fixture()
      schedule_b = schedule_fixture(operator_id: org_b.id)

      assert_error_sent 404, fn ->
        post(build_conn(), ~p"/book/#{org_a.slug}/#{schedule_b.id}", %{
          "booking" => %{"passenger_name" => "Attacker", "travel_date" => "2026-01-01"}
        })
      end
    end

    test "book/2 succeeds when the schedule does belong to the operator in the URL" do
      org_a = operator_fixture()
      schedule_a = schedule_fixture(operator_id: org_a.id)

      conn = get(build_conn(), ~p"/book/#{org_a.slug}/#{schedule_a.id}")
      assert html_response(conn, 200)
    end
  end
end
