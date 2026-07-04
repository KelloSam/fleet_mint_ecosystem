defmodule FleetMintWeb.ApiController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Ticketing

  @pii_roles ~w(admin manager)

  # GET /api/notifications?since=YYYY-MM-DDTHH:MM:SS
  def notifications(conn, %{"since" => since_str}) do
    current_user = conn.assigns.current_user

    unless current_user.role in @pii_roles do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Insufficient permissions to view passenger data"})
      |> halt()
    else
      since =
        case NaiveDateTime.from_iso8601(since_str) do
          {:ok, dt} -> dt
          _ -> NaiveDateTime.add(NaiveDateTime.utc_now(), -60, :second)
        end

      bookings = Ticketing.list_bookings_since(since)

      data =
        Enum.map(bookings, fn b ->
          %{
            reference: b.booking_reference,
            passenger: b.passenger_name,
            seat: b.seat_number,
            date: to_string(b.travel_date),
            at: NaiveDateTime.to_iso8601(b.inserted_at)
          }
        end)

      json(conn, %{bookings: data})
    end
  end

  def notifications(conn, _params), do: json(conn, %{bookings: []})

  # GET /api/seats?schedule_id=X&date=YYYY-MM-DD
  def available_seats(conn, %{"schedule_id" => sid, "date" => date_str}) do
    with {schedule_id, ""} <- Integer.parse(sid),
         {:ok, date} <- Date.from_iso8601(date_str) do
      schedule = Trips.get_schedule!(schedule_id)
      taken = Ticketing.get_booked_seats(schedule_id, date)
      json(conn, %{total: schedule.available_seats, taken: taken})
    else
      _ -> json(conn, %{total: 0, taken: []})
    end
  end

  def available_seats(conn, _params), do: json(conn, %{total: 0, taken: []})
end
