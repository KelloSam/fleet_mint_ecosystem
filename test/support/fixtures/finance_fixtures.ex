defmodule FleetMint.FinanceFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `FleetMint.Finance` context.
  """

  @doc """
  Generate a report.
  """
  def report_fixture(attrs \\ %{}) do
    {:ok, report} =
      attrs
      |> Enum.into(%{
        start_date: ~D[2025-03-03],
        end_date: ~D[2025-03-03]
      })
      |> FleetMint.Finance.create_report()

    report
  end

  @doc """
  Generate a cashing_report.
  """
  def cashing_report_fixture(attrs \\ %{}) do
    # First create a report
    report = report_fixture()

    {:ok, cashing_report} =
      attrs
      |> Enum.into(%{
        airtel_id: "some airtel_id",
        days_worked: 42,
        debt_balance: "120.5",
        description: "some description",
        expected_cashing: "120.5",
        expenditure: "120.5",
        received_cashing: "120.5",
        report_id: report.id
      })
      |> FleetMint.Finance.create_cashing_report()

    cashing_report
  end

  @doc """
  Generate a expenditure.
  """
  def expenditure_fixture(attrs \\ %{}) do
    # First create a cashing_report
    cashing_report = cashing_report_fixture()

    {:ok, expenditure} =
      attrs
      |> Enum.into(%{
        amount: "120.5",
        description: "some description",
        cashing_report_id: cashing_report.id,
        date: DateTime.utc_now()
      })
      |> FleetMint.Finance.create_expenditure()

    expenditure
  end
end
