defmodule FleetMint.TicketingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.Transport.Ticketing` context.
  """

  def route_fixture(attrs \\ %{}) do
    {:ok, route} =
      attrs
      |> Enum.into(%{
        name: "Lusaka - Ndola",
        status: "active",
        start_location: "Lusaka",
        end_location: "Ndola",
        distance: "320.0",
        duration: 240,
        fare: "150.00"
      })
      |> FleetMint.Transport.Routes.create_route()

    route
  end

  def schedule_fixture(attrs \\ %{}) do
    route = route_fixture()

    {:ok, schedule} =
      attrs
      |> Enum.into(%{
        departure_time: ~T[08:00:00],
        fare: "150.00",
        available_seats: 40,
        status: "active",
        route_id: route.id
      })
      |> FleetMint.Transport.Trips.create_schedule()

    schedule
  end

  def booking_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    schedule = attrs[:schedule] || schedule_fixture()

    {:ok, booking} =
      attrs
      |> Map.delete(:schedule)
      |> Enum.into(%{
        passenger_name: "Jane Doe",
        travel_date: Date.utc_today(),
        fare_paid: schedule.fare,
        schedule_id: schedule.id
      })
      |> FleetMint.Transport.Ticketing.create_booking()

    booking
  end
end
