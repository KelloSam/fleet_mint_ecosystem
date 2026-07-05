defmodule FleetMintWeb.BookingController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Ticketing
  alias FleetMint.Transport.Ticketing.Booking
  alias FleetMint.Identity.Users

  def index(conn, params) do
    page = FleetMint.Pagination.parse_page(params)
    travel_date =
      case params["date"] do
        nil -> nil
        "" -> nil
        d ->
          case Date.from_iso8601(d) do
            {:ok, date} -> date
            _ -> nil
          end
      end
    paged = Ticketing.list_bookings_paginated(page, travel_date: travel_date, status: params["status"])
    render(conn, :index, bookings: paged.entries, paged: paged)
  end

  def new(conn, params) do
    changeset = Ticketing.change_booking(%Booking{travel_date: Date.utc_today()})
    schedules = Trips.list_schedules(status: "active")
    staff = Users.list_staff_with_phone()
    render(conn, :new, changeset: changeset, schedules: schedules,
                       prefill_schedule: params["schedule_id"], staff: staff)
  end

  def create(conn, %{"booking" => booking_params}) do
    user_id = conn.assigns[:current_user].id
    case Ticketing.create_booking(booking_params, user_id) do
      {:ok, booking} ->
        conn
        |> put_flash(:info, "Booking #{booking.booking_reference} confirmed. QR ticket issued.")
        |> redirect(to: ~p"/bookings/#{booking}")

      {:error, %Ecto.Changeset{} = changeset} ->
        schedules = Trips.list_schedules(status: "active")
        staff = Users.list_staff_with_phone()
        render(conn, :new, changeset: changeset, schedules: schedules,
                           prefill_schedule: nil, staff: staff)
    end
  end

  def show(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)
    render(conn, :show, booking: booking)
  end

  def edit(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)
    changeset = Ticketing.change_booking(booking)
    schedules = Trips.list_schedules(status: "active")
    staff = Users.list_staff_with_phone()
    render(conn, :edit, booking: booking, changeset: changeset,
                        schedules: schedules, staff: staff)
  end

  def update(conn, %{"id" => id, "booking" => booking_params}) do
    booking = Ticketing.get_booking!(id)
    case Ticketing.update_booking(booking, booking_params) do
      {:ok, booking} ->
        conn |> put_flash(:info, "Booking updated.") |> redirect(to: ~p"/bookings/#{booking}")
      {:error, changeset} ->
        schedules = Trips.list_schedules(status: "active")
        staff = Users.list_staff_with_phone()
        render(conn, :edit, booking: booking, changeset: changeset,
                            schedules: schedules, staff: staff)
    end
  end

  def delete(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)
    {:ok, _} = Ticketing.cancel_booking(booking)
    conn |> put_flash(:info, "Booking cancelled.") |> redirect(to: ~p"/bookings")
  end
end
