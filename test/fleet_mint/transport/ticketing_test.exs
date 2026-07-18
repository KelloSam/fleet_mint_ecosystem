defmodule FleetMint.Transport.TicketingTest do
  use FleetMint.DataCase

  alias FleetMint.Accounting
  alias FleetMint.Transport.Ticketing

  import FleetMint.TicketingFixtures
  import FleetMint.FleetFixtures

  describe "create_booking/2" do
    test "writes a matching revenue ledger entry" do
      schedule = schedule_fixture(fare: "200.00")

      assert {:ok, booking} =
               Ticketing.create_booking(%{
                 "passenger_name" => "Jane Doe",
                 "travel_date" => Date.utc_today(),
                 "fare_paid" => "200.00",
                 "schedule_id" => schedule.id
               })

      assert [entry] = Accounting.entries_for_source("Booking", booking.id)
      assert entry.entry_type == "revenue"
      assert Decimal.equal?(entry.amount, Decimal.new("200.00"))
      assert entry.payment_method == "cash"
    end

    test "decrements the schedule's available seats" do
      schedule = schedule_fixture(available_seats: 5)

      {:ok, booking} =
        Ticketing.create_booking(%{
          "passenger_name" => "Jane Doe",
          "travel_date" => Date.utc_today(),
          "fare_paid" => schedule.fare,
          "schedule_id" => schedule.id
        })

      assert booking.id
      reloaded = FleetMint.Transport.Trips.get_schedule!(schedule.id)
      assert reloaded.available_seats == 4
    end

    test "invalid attrs return an error changeset and write no ledger entry" do
      schedule = schedule_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Ticketing.create_booking(%{
                 "passenger_name" => nil,
                 "travel_date" => Date.utc_today(),
                 "fare_paid" => "50.00",
                 "schedule_id" => schedule.id
               })

      assert Accounting.list_entries(source_type: "Booking") == []
    end

    test "refuses to overbook once a schedule has no seats left" do
      schedule = schedule_fixture(available_seats: 0)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Ticketing.create_booking(%{
                 "passenger_name" => "Jane Doe",
                 "travel_date" => Date.utc_today(),
                 "fare_paid" => schedule.fare,
                 "schedule_id" => schedule.id
               })

      assert "no seats available on this schedule" in errors_on(changeset).schedule_id
      assert Accounting.list_entries(source_type: "Booking") == []

      reloaded = FleetMint.Transport.Trips.get_schedule!(schedule.id)
      assert reloaded.available_seats == 0
    end
  end

  describe "list_bookings/1 tenant scoping" do
    test "organisation_id filters to bookings on that organisation's schedules only" do
      operator_a = operator_fixture()
      operator_b = operator_fixture()

      booking_a = booking_fixture(schedule: schedule_fixture(operator_id: operator_a.id))
      _booking_b = booking_fixture(schedule: schedule_fixture(operator_id: operator_b.id))

      result = Ticketing.list_bookings(organisation_id: operator_a.organisation_id)

      assert Enum.map(result, & &1.id) == [booking_a.id]
    end

    test ":all bypasses the organisation filter" do
      operator_a = operator_fixture()
      operator_b = operator_fixture()

      booking_fixture(schedule: schedule_fixture(operator_id: operator_a.id))
      booking_fixture(schedule: schedule_fixture(operator_id: operator_b.id))

      result = Ticketing.list_bookings(organisation_id: :all)

      assert length(result) >= 2
    end
  end

  describe "update_booking/2" do
    test "syncs the linked ledger entry's amount" do
      booking = booking_fixture()
      assert {:ok, updated} = Ticketing.update_booking(booking, %{"fare_paid" => "500.00"})

      assert [entry] = Accounting.entries_for_source("Booking", updated.id)
      assert Decimal.equal?(entry.amount, Decimal.new("500.00"))
    end
  end

  describe "cancel_booking/1" do
    test "writes an offsetting refund entry linked to the original" do
      booking = booking_fixture(fare_paid: "80.00")
      assert {:ok, cancelled} = Ticketing.cancel_booking(booking)
      assert cancelled.status == "cancelled"

      entries = Accounting.entries_for_source("Booking", booking.id)
      assert length(entries) == 2

      revenue = Enum.find(entries, &(&1.entry_type == "revenue"))
      refund = Enum.find(entries, &(&1.entry_type == "refund"))

      assert refund.reverses_entry_id == revenue.id
      assert Decimal.equal?(refund.amount, revenue.amount)

      net = Decimal.sub(Accounting.total_for("revenue", source_type: "Booking"), Accounting.total_for("refund", source_type: "Booking"))
      assert Decimal.equal?(net, Decimal.new(0))
    end

    test "releases the seat back to the schedule" do
      schedule = schedule_fixture(available_seats: 10)
      booking = booking_fixture(schedule: schedule)
      assert %{available_seats: 9} = FleetMint.Transport.Trips.get_schedule!(schedule.id)

      assert {:ok, _cancelled} = Ticketing.cancel_booking(booking)
      assert %{available_seats: 10} = FleetMint.Transport.Trips.get_schedule!(schedule.id)
    end

    test "cancels the linked ticket so it can no longer board" do
      booking = booking_fixture()
      assert {:ok, cancelled} = Ticketing.cancel_booking(booking)

      ticket = FleetMint.Repo.get_by!(FleetMint.Transport.Ticketing.Ticket, booking_id: cancelled.id)
      assert ticket.status == "cancelled"
    end

    test "no-ops the reversal safely when the booking has no linked ledger entry" do
      booking = booking_fixture()
      Accounting.entries_for_source("Booking", booking.id) |> Enum.each(&FleetMint.Repo.delete!/1)

      assert {:ok, cancelled} = Ticketing.cancel_booking(booking)
      assert cancelled.status == "cancelled"
      assert Accounting.entries_for_source("Booking", booking.id) == []
    end
  end
end
