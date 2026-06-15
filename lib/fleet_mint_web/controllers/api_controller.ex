defmodule FleetMintWeb.ApiController do
  use FleetMintWeb, :controller
  alias FleetMint.Transit

  # GET /api/notifications?since=YYYY-MM-DDTHH:MM:SS
  def notifications(conn, %{"since" => since_str}) do
    since =
      case NaiveDateTime.from_iso8601(since_str) do
        {:ok, dt} -> dt
        _ -> NaiveDateTime.add(NaiveDateTime.utc_now(), -60, :second)
      end

    bookings = Transit.list_bookings_since(since)

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

  def notifications(conn, _params), do: json(conn, %{bookings: []})

  # GET /api/seats?schedule_id=X&date=YYYY-MM-DD
  def available_seats(conn, %{"schedule_id" => sid, "date" => date_str}) do
    with {schedule_id, ""} <- Integer.parse(sid),
         {:ok, date} <- Date.from_iso8601(date_str) do
      schedule = Transit.get_schedule!(schedule_id)
      taken = Transit.get_booked_seats(schedule_id, date)
      json(conn, %{total: schedule.available_seats, taken: taken})
    else
      _ -> json(conn, %{total: 0, taken: []})
    end
  end

  def available_seats(conn, _params), do: json(conn, %{total: 0, taken: []})
end
