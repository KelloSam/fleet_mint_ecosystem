defmodule FleetMintWeb.PublicBookingController do
  use FleetMintWeb, :controller

  alias FleetMint.Transport.Fleet
  alias FleetMint.Transit

  plug :put_layout, html: {FleetMintWeb.Layouts, :public}

  # GET /book
  def index(conn, _params) do
    operators = Fleet.list_operators_for_public()
    render(conn, :index, operators: operators)
  end

  # GET /book/ticket/:reference
  def ticket(conn, %{"reference" => ref}) do
    booking = Transit.get_booking_by_reference!(ref)
    render(conn, :ticket, booking: booking)
  end

  # GET /book/:slug
  def show(conn, %{"slug" => slug}) do
    operator = Fleet.get_operator_by_slug!(slug)
    schedules = Transit.list_public_schedules_for_operator(operator.id)
    render(conn, :show, operator: operator, schedules: schedules)
  end

  # GET /book/:slug/:schedule_id?date=YYYY-MM-DD
  def book(conn, %{"slug" => slug, "schedule_id" => sid} = params) do
    operator = Fleet.get_operator_by_slug!(slug)
    schedule = Transit.get_schedule!(sid)

    date =
      case params["date"] && Date.from_iso8601(params["date"]) do
        {:ok, d} -> d
        _ -> Date.utc_today()
      end

    taken_seats = Transit.get_booked_seats(schedule.id, date)
    render(conn, :book,
      operator: operator,
      schedule: schedule,
      date: date,
      taken_seats: taken_seats
    )
  end

  # POST /book/:slug/:schedule_id
  def create(conn, %{"slug" => slug, "schedule_id" => sid, "booking" => booking_params}) do
    operator = Fleet.get_operator_by_slug!(slug)
    schedule = Transit.get_schedule!(sid)

    # Always use the server's fare — never trust the client-submitted amount.
    booking_params =
      booking_params
      |> Map.put("schedule_id", sid)
      |> Map.put("fare_paid", schedule.fare)

    case Transit.create_booking(booking_params) do
      {:ok, booking} ->
        conn
        |> put_flash(:info, "Booking confirmed! Your QR ticket is ready.")
        |> redirect(to: ~p"/book/ticket/#{booking.booking_reference}")

      {:error, changeset} ->
        date =
          case booking_params["travel_date"] && Date.from_iso8601(booking_params["travel_date"]) do
            {:ok, d} -> d
            _ -> Date.utc_today()
          end

        taken_seats = Transit.get_booked_seats(schedule.id, date)

        conn
        |> put_flash(:error, "Please check the form and try again.")
        |> render(:book,
            operator: operator,
            schedule: schedule,
            date: date,
            taken_seats: taken_seats,
            changeset: changeset
          )
    end
  end
end
