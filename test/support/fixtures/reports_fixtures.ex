defmodule BusCashingSystem.ReportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BusCashingSystem.Reports` context.
  """

  @doc """
  Generate a report.
  """
  def report_fixture(attrs \\ %{}) do
    {:ok, report} =
      attrs
      |> Enum.into(%{
        end_date: ~D[2025-03-03],
        start_date: ~D[2025-03-03]
      })
      |> BusCashingSystem.Reports.create_report()

    report
  end
end
