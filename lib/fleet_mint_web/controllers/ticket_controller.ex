defmodule FleetMintWeb.TicketController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Ticketing
  alias FleetMint.Transport.Boarding

  def index(conn, params) do
    bookings = Ticketing.list_bookings(status: params["status"], travel_date: params["date"] && Date.from_iso8601!(params["date"]))
    render(conn, :index, bookings: bookings)
  end

  def show(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)
    render(conn, :show, booking: booking, ticket: booking.ticket)
  end

  def validate(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)
    ticket = booking.ticket
    if ticket do
      case Boarding.validate_ticket(ticket.ticket_number, :static) do
        {:ok, _ticket} ->
          conn |> put_flash(:info, "Ticket validated — passenger boarded.") |> redirect(to: ~p"/tickets/#{booking}")
        {:error, reason} ->
          msg = case reason do
            :already_boarded -> "Ticket already used — duplicate boarding attempt."
            :expired -> "Ticket has expired."
            :cancelled -> "Ticket was cancelled."
            :not_found -> "Ticket not found."
          end
          conn |> put_flash(:error, msg) |> redirect(to: ~p"/tickets/#{booking}")
      end
    else
      conn |> put_flash(:error, "No ticket found for this booking.") |> redirect(to: ~p"/bookings")
    end
  end
end
