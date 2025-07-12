defmodule BusCashingSystem.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query, warn: false
  alias BusCashingSystem.Repo

  alias BusCashingSystem.Finance.Report

  @doc """
  Returns the list of weekly_reports.

  ## Examples

      iex> list_weekly_reports()
      [%Report{}, ...]

  """
  def list_weekly_reports do
    Repo.all(Report)
  end

  @doc """
  Returns the list of reports.
  This is an alias for list_weekly_reports for backward compatibility.

  ## Examples

      iex> list_reports()
      [%Report{}, ...]

  """
  def list_reports do
    list_weekly_reports()
  end

  @doc """
  Gets a single report.

  Raises if the Report does not exist.

  ## Examples

      iex> get_report!(123)
      %Report{}

  """
  def get_report!(id), do: Repo.get!(Report, id)

  @doc """
  Creates a report.

  ## Examples

      iex> create_report(%{field: value})
      {:ok, %Report{}}

      iex> create_report(%{field: bad_value})
      {:error, ...}

  """
  def create_report(attrs \\ %{}) do
    %Report{}
    |> Report.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a report.

  ## Examples

      iex> update_report(report, %{field: new_value})
      {:ok, %Report{}}

      iex> update_report(report, %{field: bad_value})
      {:error, ...}

  """
  def update_report(%Report{} = report, attrs) do
    report
    |> Report.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Report.

  ## Examples

      iex> delete_report(report)
      {:ok, %Report{}}

      iex> delete_report(report)
      {:error, ...}

  """
  def delete_report(%Report{} = report) do
    Repo.delete(report)
  end

  @doc """
  Returns a data structure for tracking report changes.

  ## Examples

      iex> change_report(report)
      %Todo{...}

  """
  def change_report(%Report{} = report, attrs \\ %{}) do
    Report.changeset(report, attrs)
  end

  @doc """
  Returns reports within a specified date range.

  ## Parameters

    - start_date: The beginning date of the range (inclusive)
    - end_date: The ending date of the range (inclusive)

  ## Examples

      iex> get_reports_by_date_range(~D[2023-01-01], ~D[2023-01-31])
      [%Report{}, ...]

  """
  def get_reports_by_date_range(start_date, end_date) do
    from(r in Report,
      where: r.start_date >= ^start_date and r.end_date <= ^end_date,
      order_by: [asc: r.start_date]
    )
    |> Repo.all()
  end
end
