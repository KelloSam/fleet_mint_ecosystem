defmodule FleetMint.Finance.ReconciliationTest do
  use FleetMint.DataCase

  import FleetMint.FleetFixtures
  import FleetMint.CargoFixtures
  import FleetMint.TicketingFixtures
  import FleetMint.IdentityFixtures
  import FleetMint.FinanceFixtures, only: [cashing_report_fixture: 1]

  alias FleetMint.Finance.Reconciliation

  describe "tenant scoping" do
    setup do
      org_a = operator_fixture()
      org_b = operator_fixture()

      bus_a = bus_fixture(organisation_id: org_a.organisation_id)
      bus_b = bus_fixture(organisation_id: org_b.organisation_id)

      today = Date.utc_today()

      minibus_trip_fixture(bus: bus_a, date: today, fare_collected: "100.00")
      minibus_trip_fixture(bus: bus_b, date: today, fare_collected: "200.00")

      cashing_report_fixture(bus_id: bus_a.id, report_date: today)
      cashing_report_fixture(bus_id: bus_b.id, report_date: today)

      %{org_a: org_a, org_b: org_b, bus_a: bus_a, bus_b: bus_b, today: today}
    end

    test "minibus_variance_for_date/2 only includes the given organisation's buses", %{
      org_a: org_a,
      bus_a: bus_a,
      bus_b: bus_b,
      today: today
    } do
      results = Reconciliation.minibus_variance_for_date(today, org_a.organisation_id)
      bus_ids = Enum.map(results, & &1.bus.id)

      assert bus_a.id in bus_ids
      refute bus_b.id in bus_ids
    end

    test "minibus_variance_for_date/2 with :all sees every organisation's buses", %{
      today: today
    } do
      trip_totals =
        FleetMint.Repo.all(
          Ecto.Query.from(t in FleetMint.Transport.Trips.MinibusTrip, where: t.date == ^today)
        )

      assert length(trip_totals) == 2
    end

    test "freight_invoice_aging/1 only includes the given organisation's clients", %{
      org_a: org_a,
      org_b: org_b
    } do
      client_a = client_fixture(%{organisation_id: org_a.organisation_id})
      client_b = client_fixture(%{organisation_id: org_b.organisation_id})

      invoice_fixture(%{client: client_a, base_amount: "500.00"})
      invoice_fixture(%{client: client_b, base_amount: "700.00"})

      aging_a = Reconciliation.freight_invoice_aging(org_a.organisation_id)
      aging_all = Reconciliation.freight_invoice_aging(:all)

      count_a = Enum.reduce(aging_a, 0, &(&2 + &1.count))
      count_all = Enum.reduce(aging_all, 0, &(&2 + &1.count))

      assert count_a < count_all
    end

    test "intercity_collections_for_date/2 only includes the given organisation's bookings", %{
      org_a: org_a,
      org_b: org_b,
      today: today
    } do
      schedule_a = schedule_fixture(operator_id: org_a.id)
      schedule_b = schedule_fixture(operator_id: org_b.id)

      cashier_a = user_fixture(role: "cashier", organisation_id: org_a.organisation_id)
      cashier_b = user_fixture(role: "cashier", organisation_id: org_b.organisation_id)

      booking_fixture(schedule: schedule_a, travel_date: today, booked_by_id: cashier_a.id)
      booking_fixture(schedule: schedule_b, travel_date: today, booked_by_id: cashier_b.id)

      collections_a = Reconciliation.intercity_collections_for_date(today, org_a.organisation_id)
      collections_all = Reconciliation.intercity_collections_for_date(today, :all)

      count_a = collections_a |> Map.values() |> List.flatten() |> length()
      count_all = collections_all |> Map.values() |> List.flatten() |> length()

      assert count_a < count_all
    end
  end
end
