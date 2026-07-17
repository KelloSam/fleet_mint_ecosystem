defmodule FleetMint.Transport.BoardingTest do
  use FleetMint.DataCase

  alias FleetMint.Repo
  alias FleetMint.Transport.Boarding
  alias FleetMint.Transport.Ticketing
  alias FleetMint.Transport.Ticketing.{Booking, Ticket}

  import FleetMint.TicketingFixtures

  describe "validate_ticket/2" do
    test "boards a valid, unused ticket" do
      booking = booking_fixture()
      ticket = Repo.get_by!(Ticket, booking_id: booking.id)

      assert {:ok, boarded} = Boarding.validate_ticket(ticket.ticket_number)
      assert boarded.status == "boarded"
    end

    test "rejects a ticket whose booking was cancelled through cancel_booking/1" do
      booking = booking_fixture()
      ticket = Repo.get_by!(Ticket, booking_id: booking.id)

      assert {:ok, _cancelled} = Ticketing.cancel_booking(booking)

      assert {:error, :cancelled} = Boarding.validate_ticket(ticket.ticket_number)
    end

    test "rejects a ticket whose parent booking is cancelled even if the ticket itself was not" do
      booking = booking_fixture()
      ticket = Repo.get_by!(Ticket, booking_id: booking.id)

      # Simulate data that predates the booking->ticket cancellation fix:
      # booking cancelled directly, bypassing Ticketing.cancel_booking/1.
      booking |> Booking.changeset(%{status: "cancelled"}) |> Repo.update!()

      assert {:error, :booking_cancelled} = Boarding.validate_ticket(ticket.ticket_number)

      reloaded = Repo.get!(Ticket, ticket.id)
      assert reloaded.status == "issued"
    end

    test "returns :not_found for an unknown ticket number" do
      assert {:error, :not_found} = Boarding.validate_ticket("TKT-000000000")
    end
  end
end
