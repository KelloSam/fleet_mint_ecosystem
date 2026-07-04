defmodule FleetMint.CargoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.Cargo` context.
  """

  def client_fixture(attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(%{
        company_name: "Acme Mining Ltd",
        client_type: "mining_company"
      })
      |> FleetMint.Cargo.create_client()

    client
  end

  def vehicle_fixture(attrs \\ %{}) do
    {:ok, vehicle} =
      attrs
      |> Enum.into(%{
        "truck_profile" => %{"payload_capacity_tons" => "20.0"},
        "registration_number" => "ABC #{System.unique_integer([:positive])} ZM",
        "make" => "Volvo",
        "model" => "FH16",
        "vehicle_type" => "truck"
      })
      |> FleetMint.Transport.Fleet.create_vehicle()

    vehicle
  end

  def trip_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    vehicle = attrs[:vehicle] || vehicle_fixture()

    {:ok, trip} =
      attrs
      |> Map.delete(:vehicle)
      |> Enum.into(%{
        origin: "Lusaka",
        destination: "Ndola",
        vehicle_id: vehicle.id
      })
      |> FleetMint.Cargo.create_trip()

    trip
  end

  def invoice_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs)
    client = attrs[:client] || client_fixture()
    trip = attrs[:trip] || trip_fixture()

    {:ok, invoice} =
      attrs
      |> Map.drop([:client, :trip])
      |> Enum.into(%{
        invoice_date: Date.utc_today(),
        base_amount: "1000.00",
        client_id: client.id,
        trip_id: trip.id
      })
      |> FleetMint.Cargo.create_invoice()

    invoice
  end
end
