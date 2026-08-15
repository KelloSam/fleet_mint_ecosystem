defmodule FleetMintWeb.BookingController do
  use FleetMintWeb, :controller
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Ticketing
  alias FleetMint.Transport.Ticketing.Booking
  alias FleetMint.Transport.Fleet
  alias FleetMint.Identity.Users
  alias FleetMint.Identity.Authorization

  def index(conn, params) do
    page = FleetMint.Pagination.parse_page(params)

    travel_date =
      case params["date"] do
        nil ->
          nil

        "" ->
          nil

        d ->
          case Date.from_iso8601(d) do
            {:ok, date} -> date
            _ -> nil
          end
      end

    paged =
      Ticketing.list_bookings_paginated(page,
        travel_date: travel_date,
        status: params["status"],
        organisation_id: conn.assigns.organisation_scope
      )

    render(conn, :index, bookings: paged.entries, paged: paged)
  end

  def new(conn, params) do
    changeset = Ticketing.change_booking(%Booking{travel_date: Date.utc_today()})

    schedules =
      Trips.list_schedules(status: "active", organisation_id: conn.assigns.organisation_scope)

    staff = Users.list_staff_with_phone(organisation_id: conn.assigns.organisation_scope)
    terminals = Fleet.list_terminals(conn.assigns.organisation_scope)

    render(conn, :new,
      changeset: changeset,
      schedules: schedules,
      prefill_schedule: params["schedule_id"],
      staff: staff,
      terminals: terminals
    )
  end

  def create(conn, %{"booking" => booking_params}) do
    user_id = conn.assigns[:current_user].id
    booking_params = normalize_terminal_id(booking_params)

    schedules =
      Trips.list_schedules(status: "active", organisation_id: conn.assigns.organisation_scope)

    terminals = Fleet.list_terminals(conn.assigns.organisation_scope)

    if schedule_allowed?(schedules, booking_params["schedule_id"]) and
         terminal_allowed?(terminals, booking_params["terminal_id"]) do
      case Ticketing.create_booking(booking_params, user_id) do
        {:ok, booking} ->
          conn
          |> put_flash(:info, "Booking #{booking.booking_reference} confirmed. QR ticket issued.")
          |> redirect(to: ~p"/bookings/#{booking}")

        {:error, %Ecto.Changeset{} = changeset} ->
          staff = Users.list_staff_with_phone(organisation_id: conn.assigns.organisation_scope)

          render(conn, :new,
            changeset: changeset,
            schedules: schedules,
            prefill_schedule: nil,
            staff: staff,
            terminals: terminals
          )
      end
    else
      changeset = Ticketing.change_booking(%Booking{travel_date: Date.utc_today()})
      staff = Users.list_staff_with_phone(organisation_id: conn.assigns.organisation_scope)

      conn
      |> put_flash(:error, "That schedule or terminal is not available to you.")
      |> render(:new,
        changeset: changeset,
        schedules: schedules,
        prefill_schedule: nil,
        staff: staff,
        terminals: terminals
      )
    end
  end

  def show(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)

    with_organisation_access(conn, booking.schedule.operator, ~p"/bookings", fn conn ->
      render(conn, :show, booking: booking)
    end)
  end

  def edit(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)

    with_organisation_access(conn, booking.schedule.operator, ~p"/bookings", fn conn ->
      changeset = Ticketing.change_booking(booking)

      schedules =
        Trips.list_schedules(status: "active", organisation_id: conn.assigns.organisation_scope)

      staff = Users.list_staff_with_phone(organisation_id: conn.assigns.organisation_scope)

      render(conn, :edit,
        booking: booking,
        changeset: changeset,
        schedules: schedules,
        staff: staff
      )
    end)
  end

  def update(conn, %{"id" => id, "booking" => booking_params}) do
    booking = Ticketing.get_booking!(id)

    with_organisation_access(conn, booking.schedule.operator, ~p"/bookings", fn conn ->
      case Ticketing.update_booking(booking, booking_params) do
        {:ok, booking} ->
          conn |> put_flash(:info, "Booking updated.") |> redirect(to: ~p"/bookings/#{booking}")

        {:error, changeset} ->
          schedules =
            Trips.list_schedules(
              status: "active",
              organisation_id: conn.assigns.organisation_scope
            )

          staff = Users.list_staff_with_phone(organisation_id: conn.assigns.organisation_scope)

          render(conn, :edit,
            booking: booking,
            changeset: changeset,
            schedules: schedules,
            staff: staff
          )
      end
    end)
  end

  def delete(conn, %{"id" => id}) do
    booking = Ticketing.get_booking!(id)

    with_organisation_access(conn, booking.schedule.operator, ~p"/bookings", fn conn ->
      {:ok, _} = Ticketing.cancel_booking(booking)
      conn |> put_flash(:info, "Booking cancelled.") |> redirect(to: ~p"/bookings")
    end)
  end

  # ── Tenant scoping helpers ──────────────────────────────────────────────

  defp normalize_terminal_id(%{"terminal_id" => ""} = params),
    do: Map.delete(params, "terminal_id")

  defp normalize_terminal_id(params), do: params

  defp schedule_allowed?(schedules, schedule_id) do
    schedule_id = to_string(schedule_id)
    Enum.any?(schedules, &(to_string(&1.id) == schedule_id))
  end

  defp terminal_allowed?(_terminals, nil), do: true

  defp terminal_allowed?(terminals, terminal_id) do
    terminal_id = to_string(terminal_id)
    Enum.any?(terminals, &(to_string(&1.id) == terminal_id))
  end

  defp with_organisation_access(conn, operator, fallback_path, fun) do
    organisation_id = operator && operator.organisation_id

    if Authorization.can_access_organisation?(conn.assigns.current_user, organisation_id) do
      fun.(conn)
    else
      conn
      |> put_flash(:error, "That booking belongs to a different organisation.")
      |> redirect(to: fallback_path)
    end
  end
end
