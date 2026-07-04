defmodule FleetMint.AccountingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.Accounting` context.
  """

  def ledger_entry_fixture(attrs \\ %{}) do
    {:ok, entry} =
      attrs
      |> Enum.into(%{
        entry_type: "revenue",
        source_type: "Booking",
        source_id: System.unique_integer([:positive]),
        amount: "100.00"
      })
      |> FleetMint.Accounting.record_entry()

    entry
  end
end
