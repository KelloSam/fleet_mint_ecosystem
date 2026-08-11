defmodule FleetMintWeb.TicketController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Ticketing
  alias FleetMint.Transport.Boarding
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    bookings =
      Ticketing.list_bookings(
        status: params["status"],
        travel_date: params["date"] && Date.from_iso8601!(params["date"]),
        organisation_id: conn.assigns.organisation_scope
      )

    render(conn, :index, bookings: bookings)
  end

  def show(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)

    with_organisation_access(conn, booking.schedule.operator, ~p"/tickets", fn conn ->
      render(conn, :show, booking: booking, ticket: booking.ticket)
    end)
  end

  def validate(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)

    with_organisation_access(conn, booking.schedule.operator, ~p"/tickets", fn conn ->
      ticket = booking.ticket

      if ticket do
        case Boarding.validate_ticket(ticket.ticket_number, :static) do
          {:ok, _ticket} ->
            conn
            |> put_flash(:info, "Ticket validated — passenger boarded.")
            |> redirect(to: ~p"/tickets/#{booking}")

          {:error, reason} ->
            msg =
              case reason do
                :already_boarded -> "Ticket already used — duplicate boarding attempt."
                :expired -> "Ticket has expired."
                :cancelled -> "Ticket was cancelled."
                :booking_cancelled -> "Booking was cancelled — ticket is not valid for boarding."
                :not_found -> "Ticket not found."
              end

            conn |> put_flash(:error, msg) |> redirect(to: ~p"/tickets/#{booking}")
        end
      else
        conn
        |> put_flash(:error, "No ticket found for this booking.")
        |> redirect(to: ~p"/bookings")
      end
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp with_organisation_access(conn, operator, fallback_path, fun) do
    organisation_id = operator && operator.organisation_id

    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That ticket belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
