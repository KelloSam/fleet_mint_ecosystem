defmodule FleetMintWeb.BookingController do
  use FleetMintWeb, :controller
  alias FleetMint.Transit
  alias FleetMint.Transit.Booking
  alias FleetMint.Accounts

  def index(conn, params) do
    bookings = Transit.list_bookings(
      travel_date: params["date"] && Date.from_iso8601!(params["date"]),
      status: params["status"]
    )
    render(conn, :index, bookings: bookings)
  end

  def new(conn, params) do
    changeset = Transit.change_booking(%Booking{travel_date: Date.utc_today()})
    schedules = Transit.list_schedules(status: "active")
    staff = Accounts.list_staff_with_phone()
    render(conn, :new, changeset: changeset, schedules: schedules,
                       prefill_schedule: params["schedule_id"], staff: staff)
  end

  def create(conn, %{"booking" => booking_params}) do
    user_id = conn.assigns[:current_user].id
    case Transit.create_booking(booking_params, user_id) do
      {:ok, booking} ->
        conn
        |> put_flash(:info, "Booking #{booking.booking_reference} confirmed. QR ticket issued.")
        |> redirect(to: ~p"/bookings/#{booking}")

      {:error, %Ecto.Changeset{} = changeset} ->
        schedules = Transit.list_schedules(status: "active")
        staff = Accounts.list_staff_with_phone()
        render(conn, :new, changeset: changeset, schedules: schedules,
                           prefill_schedule: nil, staff: staff)
    end
  end

  def show(conn, %{"id" => id}) do
    booking = Transit.get_booking!(id)
    render(conn, :show, booking: booking)
  end

  def edit(conn, %{"id" => id}) do
    booking = Transit.get_booking!(id)
    changeset = Transit.change_booking(booking)
    schedules = Transit.list_schedules(status: "active")
    staff = Accounts.list_staff_with_phone()
    render(conn, :edit, booking: booking, changeset: changeset,
                        schedules: schedules, staff: staff)
  end

  def update(conn, %{"id" => id, "booking" => booking_params}) do
    booking = Transit.get_booking!(id)
    case Transit.update_booking(booking, booking_params) do
      {:ok, booking} ->
        conn |> put_flash(:info, "Booking updated.") |> redirect(to: ~p"/bookings/#{booking}")
      {:error, changeset} ->
        schedules = Transit.list_schedules(status: "active")
        staff = Accounts.list_staff_with_phone()
        render(conn, :edit, booking: booking, changeset: changeset,
                            schedules: schedules, staff: staff)
    end
  end

  def delete(conn, %{"id" => id}) do
    booking = Transit.get_booking!(id)
    {:ok, _} = Transit.cancel_booking(booking)
    conn |> put_flash(:info, "Booking cancelled.") |> redirect(to: ~p"/bookings")
  end
end
