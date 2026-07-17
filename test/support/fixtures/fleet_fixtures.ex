defmodule FleetMint.FleetFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.Transport.Fleet` context.
  """

  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Routes

  def bus_fixture(attrs \\ %{}) do
    {:ok, bus} =
      attrs
      |> Enum.into(%{
        registration_number: "BUS#{System.unique_integer([:positive])}ZM",
        capacity: 60,
        model: "Yutong",
        year: 2022,
        status: "active"
      })
      |> Fleet.create_bus()

    bus
  end

  def operator_fixture(attrs \\ %{}) do
    n = System.unique_integer([:positive])

    {:ok, operator} =
      attrs
      |> Enum.into(%{name: "Test Bus Services #{n}", slug: "test-bus-#{n}"})
      |> Fleet.create_operator()

    operator
  end

  def branch_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    operator = attrs[:operator] || operator_fixture()

    {:ok, branch} =
      attrs
      |> Map.delete(:operator)
      |> Enum.into(%{name: "Head Office", operator_id: operator.id})
      |> Fleet.create_branch()

    branch
  end

  def terminal_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    branch = attrs[:branch] || branch_fixture()

    {:ok, terminal} =
      attrs
      |> Map.delete(:branch)
      |> Enum.into(%{name: "Main Terminal", branch_id: branch.id, operator_id: branch.operator_id})
      |> Fleet.create_terminal()

    terminal
  end

  def route_fixture(attrs \\ %{}) do
    {:ok, route} =
      attrs
      |> Enum.into(%{
        name: "Lusaka - Kabwe",
        status: "active",
        start_location: "Lusaka",
        end_location: "Kabwe",
        distance: "140.0",
        duration: 120,
        fare: "80.00"
      })
      |> Routes.create_route()

    route
  end

  def minibus_trip_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    bus = attrs[:bus] || bus_fixture()
    route = attrs[:route] || route_fixture()

    {:ok, trip} =
      attrs
      |> Map.drop([:bus, :route])
      |> Enum.into(%{
        date: Date.utc_today(),
        bus_id: bus.id,
        route_id: route.id
      })
      |> FleetMint.Transport.Trips.create_minibus_trip()

    trip
  end

  def vehicle_fixture(attrs \\ %{}) do
    {:ok, vehicle} =
      attrs
      |> Enum.into(%{
        "registration_number" => "VEH #{System.unique_integer([:positive])} ZM",
        "make" => "Toyota",
        "model" => "Hilux",
        "vehicle_type" => "truck",
        "truck_profile" => %{"payload_capacity_tons" => "3.0"}
      })
      |> Fleet.create_vehicle()

    vehicle
  end

  def fuel_log_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    vehicle = attrs[:vehicle] || vehicle_fixture()

    {:ok, fuel_log} =
      attrs
      |> Map.delete(:vehicle)
      |> Enum.into(%{
        log_date: Date.utc_today(),
        liters: "50.0",
        vehicle_id: vehicle.id
      })
      |> Fleet.create_fuel_log()

    fuel_log
  end

  def maintenance_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    vehicle = attrs[:vehicle] || vehicle_fixture()

    {:ok, maintenance} =
      attrs
      |> Map.delete(:vehicle)
      |> Enum.into(%{
        service_date: Date.utc_today(),
        service_type: "oil_change",
        vehicle_id: vehicle.id
      })
      |> Fleet.create_maintenance()

    maintenance
  end
end
