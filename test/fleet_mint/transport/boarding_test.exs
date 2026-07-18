defmodule FleetMint.Transport.BoardingTest do
  use FleetMint.DataCase

  alias FleetMint.Repo
  alias FleetMint.Transport.Boarding
  alias FleetMint.Transport.Boarding.BusCheckpoint
  alias FleetMint.Transport.Ticketing
  alias FleetMint.Transport.Ticketing.{Booking, Ticket}
  alias FleetMint.Transport.Trips

  import FleetMint.TicketingFixtures
  import FleetMint.FleetFixtures

  describe "validate_ticket/2" do
    test "boards a valid, unused ticket" do
      booking = booking_fixture()
      ticket = Repo.get_by!(Ticket, booking_id: booking.id)

      assert {:ok, boarded} = Boarding.validate_ticket(ticket.ticket_number)
      assert boarded.status == "boarded"
    end

    test "rejects a ticket whose booking was cancelled through cancel_booking/1" do
      booking = booking_fixture()
      ticket = Repo.get_by!(Ticket, booking_id: booking.id)

      assert {:ok, _cancelled} = Ticketing.cancel_booking(booking)

      assert {:error, :cancelled} = Boarding.validate_ticket(ticket.ticket_number)
    end

    test "rejects a ticket whose parent booking is cancelled even if the ticket itself was not" do
      booking = booking_fixture()
      ticket = Repo.get_by!(Ticket, booking_id: booking.id)

      # Simulate data that predates the booking->ticket cancellation fix:
      # booking cancelled directly, bypassing Ticketing.cancel_booking/1.
      booking |> Booking.changeset(%{status: "cancelled"}) |> Repo.update!()

      assert {:error, :booking_cancelled} = Boarding.validate_ticket(ticket.ticket_number)

      reloaded = Repo.get!(Ticket, ticket.id)
      assert reloaded.status == "issued"
    end

    test "returns :not_found for an unknown ticket number" do
      assert {:error, :not_found} = Boarding.validate_ticket("TKT-000000000")
    end
  end

  describe "get_or_create_trip/2" do
    test "derives organisation_id from the schedule's operator, not from the caller" do
      operator = operator_fixture()
      schedule = schedule_fixture(operator_id: operator.id)

      assert {:ok, trip} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])
      assert trip.organisation_id == operator.organisation_id
      assert trip.status == "planned"
    end

    test "is idempotent — the same (schedule, day) returns the same Trip" do
      operator = operator_fixture()
      schedule = schedule_fixture(operator_id: operator.id)

      assert {:ok, trip1} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])
      assert {:ok, trip2} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])
      assert trip1.id == trip2.id
    end
  end

  describe "post_checkpoint/1" do
    test "resolves (creating) the Trip and stamps trip_id/organisation_id on the checkpoint" do
      operator = operator_fixture()
      schedule = schedule_fixture(operator_id: operator.id)

      assert {:ok, checkpoint} =
               Boarding.post_checkpoint(%{
                 "schedule_id" => schedule.id,
                 "travel_date" => "2026-08-01",
                 "location" => "Kabwe"
               })

      trip = Trips.get_trip!(checkpoint.trip_id)
      assert trip.schedule_id == schedule.id
      assert trip.travel_date == ~D[2026-08-01]
      assert checkpoint.organisation_id == operator.organisation_id
    end

    test "two checkpoints on the same schedule/day share the same Trip" do
      operator = operator_fixture()
      schedule = schedule_fixture(operator_id: operator.id)

      {:ok, cp1} = Boarding.post_checkpoint(%{"schedule_id" => schedule.id, "travel_date" => "2026-08-01", "location" => "Kabwe"})
      {:ok, cp2} = Boarding.post_checkpoint(%{"schedule_id" => schedule.id, "travel_date" => "2026-08-01", "location" => "Kapiri"})

      assert cp1.trip_id == cp2.trip_id
    end

    test "rejects an invalid travel_date instead of crashing" do
      operator = operator_fixture()
      schedule = schedule_fixture(operator_id: operator.id)

      assert {:error, changeset} =
               Boarding.post_checkpoint(%{"schedule_id" => schedule.id, "travel_date" => "not-a-date", "location" => "Kabwe"})

      assert "must be a valid date for an existing schedule" in errors_on(changeset).travel_date
    end
  end

  describe "tenant isolation at the database level" do
    test "a checkpoint cannot be inserted with a trip_id/organisation_id mismatch" do
      operator_a = operator_fixture()
      operator_b = operator_fixture()
      schedule = schedule_fixture(operator_id: operator_a.id)

      {:ok, trip} = Trips.get_or_create_trip(schedule.id, ~D[2026-08-01])
      assert trip.organisation_id == operator_a.organisation_id

      changeset =
        %BusCheckpoint{}
        |> BusCheckpoint.changeset(%{
          "location" => "Tampered",
          "travel_date" => "2026-08-01",
          "schedule_id" => schedule.id
        })
        |> Ecto.Changeset.put_change(:trip_id, trip.id)
        # Wrong organisation on purpose — must not be accepted even though
        # trip_id alone points at a real Trip.
        |> Ecto.Changeset.put_change(:organisation_id, operator_b.organisation_id)

      # No caller-facing path can produce this (post_checkpoint/1 always
      # stamps both fields from the same Trip) — this proves the database
      # itself refuses the mismatch, not just the application code.
      assert_raise Ecto.ConstraintError, fn -> Repo.insert(changeset) end
    end
  end
end
