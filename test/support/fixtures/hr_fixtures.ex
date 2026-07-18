defmodule FleetMint.HRFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.HR` context.
  """

  def driver_fixture(attrs \\ %{}) do
    {:ok, driver} =
      attrs
      |> Enum.into(%{
        name: "Test Driver #{System.unique_integer([:positive])}",
        status: "active"
      })
      |> FleetMint.HR.create_driver()

    driver
  end
end
