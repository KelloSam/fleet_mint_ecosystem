defmodule FleetMintWeb.TicketControllerTest do
  use FleetMintWeb.ConnCase

  import FleetMint.FleetFixtures
  import FleetMint.TicketingFixtures
  import FleetMint.IdentityFixtures

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      schedule_a = schedule_fixture(operator_id: org_a.id)
      schedule_b = schedule_fixture(operator_id: org_b.id)

      booking_a = booking_fixture(schedule: schedule_a)
      booking_b = booking_fixture(schedule: schedule_b)
      ticket_b = booking_b.ticket

      staff_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)

      %{
        org_a: org_a,
        org_b: org_b,
        booking_a: booking_a,
        booking_b: booking_b,
        ticket_b: ticket_b,
        staff_a: staff_a
      }
    end

    test "index only lists the caller's own organisation's bookings", %{
      conn: conn,
      staff_a: staff_a,
      booking_a: booking_a,
      booking_b: booking_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/tickets")
      html_response(conn, 200)

      listed_ids = Enum.map(conn.assigns.bookings, & &1.id)
      assert booking_a.id in listed_ids
      refute booking_b.id in listed_ids
    end

    test "prohibited: cannot view another organisation's ticket/booking", %{
      conn: conn,
      staff_a: staff_a,
      booking_b: booking_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/tickets/#{booking_b}")

      assert redirected_to(conn) == ~p"/tickets"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
    end

    test "prohibited: cannot validate (board) another organisation's ticket", %{
      conn: conn,
      staff_a: staff_a,
      booking_b: booking_b,
      ticket_b: ticket_b
    } do
      conn = conn |> log_in_user(staff_a) |> get(~p"/tickets/#{booking_b}/validate")

      assert redirected_to(conn) == ~p"/tickets"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "different organisation"
      assert FleetMint.Repo.reload!(ticket_b).status == "issued"
    end
  end
end
