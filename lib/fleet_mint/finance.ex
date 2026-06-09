defmodule FleetMint.Finance do
  @moduledoc """
  The Finance context.
  """

  import Ecto.Query, warn: false
  alias FleetMint.Repo

  alias FleetMint.Finance.CashingReport

  @doc """
  Returns the list of cashing_reports.

  ## Examples

      iex> list_cashing_reports()
      [%CashingReport{}, ...]

  """
  def list_cashing_reports do
    Repo.all(CashingReport)
  end

  @doc """
  Gets a single cashing_report.

  Raises if the Cashing report does not exist.

  ## Examples

      iex> get_cashing_report!(123)
      %CashingReport{}

  """
  def get_cashing_report!(id), do: Repo.get!(CashingReport, id)

  @doc """
  Creates a cashing_report.

  ## Examples

      iex> create_cashing_report(%{field: value})
      {:ok, %CashingReport{}}

      iex> create_cashing_report(%{field: bad_value})
      {:error, ...}

  """
  def create_cashing_report(attrs \\ %{}) do
    %CashingReport{}
    |> CashingReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a cashing_report.

  ## Examples

      iex> update_cashing_report(cashing_report, %{field: new_value})
      {:ok, %CashingReport{}}

      iex> update_cashing_report(cashing_report, %{field: bad_value})
      {:error, ...}

  """
  def update_cashing_report(%CashingReport{} = cashing_report, attrs) do
    cashing_report
    |> CashingReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a CashingReport.

  ## Examples

      iex> delete_cashing_report(cashing_report)
      {:ok, %CashingReport{}}

      iex> delete_cashing_report(cashing_report)
      {:error, ...}

  """
  def delete_cashing_report(%CashingReport{} = cashing_report) do
    Repo.delete(cashing_report)
  end

  @doc """
  Returns a data structure for tracking cashing_report changes.

  ## Examples

      iex> change_cashing_report(cashing_report)
      %Todo{...}

  """
  def change_cashing_report(%CashingReport{} = cashing_report, attrs \\ %{}) do
    CashingReport.changeset(cashing_report, attrs)
  end

  @doc """
  Returns the list of cashing_reports for a specific weekly report.

  ## Examples

      iex> get_cashing_reports_by_report(report_id)
      [%CashingReport{}, ...]

  """
  def get_cashing_reports_by_report(report_id) do
    query = from cr in CashingReport,
            where: cr.report_id == ^report_id,
            order_by: [desc: cr.inserted_at]
    Repo.all(query)
  end

  alias FleetMint.Finance.Report

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

  alias FleetMint.Finance.Expenditure

  @doc """
  Returns the list of expenditures.

  ## Examples

      iex> list_expenditures()
      [%Expenditure{}, ...]

  """
  def list_expenditures do
    query = from e in Expenditure,
            order_by: [desc: e.date]
    Repo.all(query)
  end

  @doc """
  Gets a single expenditure.

  Raises if the Expenditure does not exist.

  ## Examples

      iex> get_expenditure!(123)
      %Expenditure{}

  """
  def get_expenditure!(id), do: Repo.get!(Expenditure, id)

  @doc """
  Creates a expenditure.

  ## Examples

      iex> create_expenditure(%{field: value})
      {:ok, %Expenditure{}}

      iex> create_expenditure(%{field: bad_value})
      {:error, ...}

  """
  def create_expenditure(attrs \\ %{}) do
    %Expenditure{}
    |> Expenditure.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a expenditure.

  ## Examples

      iex> update_expenditure(expenditure, %{field: new_value})
      {:ok, %Expenditure{}}

      iex> update_expenditure(expenditure, %{field: bad_value})
      {:error, ...}

  """
  def update_expenditure(%Expenditure{} = expenditure, attrs) do
    expenditure
    |> Expenditure.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Expenditure.

  ## Examples

      iex> delete_expenditure(expenditure)
      {:ok, %Expenditure{}}

      iex> delete_expenditure(expenditure)
      {:error, ...}

  """
  def delete_expenditure(%Expenditure{} = expenditure) do
    Repo.delete(expenditure)
  end

  @doc """
  Returns a data structure for tracking expenditure changes.

  ## Examples

      iex> change_expenditure(expenditure)
      %Todo{...}

  """
  def change_expenditure(%Expenditure{} = expenditure, attrs \\ %{}) do
    Expenditure.changeset(expenditure, attrs)
  end

  @doc """
  Returns the list of expenditures for a specific cashing report.

  ## Examples

      iex> get_expenditures_by_cashing_report(cashing_report_id)
      [%Expenditure{}, ...]

  """
  def get_expenditures_by_cashing_report(cashing_report_id) do
    query = from e in Expenditure,
            where: e.cashing_report_id == ^cashing_report_id,
            order_by: [desc: e.inserted_at]
    Repo.all(query)
  end

  @doc """
  Calculates the total of all expenditures for a specific cashing report.

  ## Examples

      iex> calculate_total_expenditures(cashing_report_id)
      #Decimal<100.50>

  """
  def calculate_total_expenditures(cashing_report_id) do
    query = from e in Expenditure,
            where: e.cashing_report_id == ^cashing_report_id,
            select: sum(e.amount)
    Repo.one(query) || Decimal.new("0.00")
  end

  @doc """
  Returns the list of expenditures within a specified date range.

  ## Examples

      iex> list_expenditures_by_date_range(~D[2025-04-01], ~D[2025-04-07])
      [%Expenditure{}, ...]

  """
  def list_expenditures_by_date_range(start_date, end_date) do
    start_datetime = start_date |> NaiveDateTime.new!(~T[00:00:00.000]) |> NaiveDateTime.truncate(:second)
    end_datetime = end_date |> NaiveDateTime.new!(~T[23:59:59.999]) |> NaiveDateTime.truncate(:second)
    
    query = from e in Expenditure,
            where: e.date >= ^start_datetime and e.date <= ^end_datetime,
            order_by: [asc: e.date]
    
    Repo.all(query)
  end

  @doc """
  Calculates the total amount of expenditures within a specified date range.

  ## Examples

      iex> calculate_total_expenditures_by_date_range(~D[2025-04-01], ~D[2025-04-07])
      #Decimal<320.50>

  """
  def calculate_total_expenditures_by_date_range(start_date, end_date) do
    start_datetime = start_date |> NaiveDateTime.new!(~T[00:00:00.000]) |> NaiveDateTime.truncate(:second)
    end_datetime = end_date |> NaiveDateTime.new!(~T[23:59:59.999]) |> NaiveDateTime.truncate(:second)
    
    query = from e in Expenditure,
            where: e.date >= ^start_datetime and e.date <= ^end_datetime,
            select: sum(e.amount)
    
    Repo.one(query) || Decimal.new("0.00")
  end

  @doc """
  Groups expenditures by date and returns a map with dates as keys and expenditure lists as values.

  ## Examples

      iex> group_expenditures_by_date([%Expenditure{}, ...])
      %{
        ~D[2025-04-01] => [%Expenditure{}, ...],
        ~D[2025-04-02] => [%Expenditure{}, ...]
      }

  """
  def group_expenditures_by_date(expenditures) when is_list(expenditures) do
    Enum.group_by(expenditures, fn expenditure -> 
      NaiveDateTime.to_date(expenditure.date)
    end)
  end

  @doc """
  Generates a daily expenditure report for a specific date.

  ## Examples

      iex> get_daily_expenditure_report(~D[2025-04-06])
      %{
        date: ~D[2025-04-06],
        total_expenditures: #Decimal<120.50>,
        expenditure_count: 5,
        expenditures: [%Expenditure{}, ...],
        average_expenditure: #Decimal<24.10>
      }

  """
  def get_daily_expenditure_report(date) do
    expenditures = 
      date
      |> NaiveDateTime.new!(~T[00:00:00.000])
      |> NaiveDateTime.truncate(:second)
      |> then(fn start_datetime -> 
        end_datetime = date |> NaiveDateTime.new!(~T[23:59:59.999]) |> NaiveDateTime.truncate(:second)
        
        query = from e in Expenditure,
                where: e.date >= ^start_datetime and e.date <= ^end_datetime,
                order_by: [asc: e.date]
        
        Repo.all(query)
      end)

    total = Enum.reduce(expenditures, Decimal.new("0.00"), fn expenditure, acc ->
      Decimal.add(acc, expenditure.amount)
    end)

    count = length(expenditures)
    
    average = if count > 0 do
      Decimal.div(total, Decimal.new(count))
    else
      Decimal.new("0.00")
    end

    %{
      date: date,
      total_expenditures: total,
      expenditure_count: count,
      expenditures: expenditures,
      average_expenditure: average
    }
  end

  @doc """
  Generates a monthly expenditure report for a specific year and month.

  ## Examples

      iex> get_monthly_expenditure_report(2025, 4)
      %{
        year: 2025,
        month: 4,
        total_expenditures: #Decimal<2500.00>,
        expenditure_count: 45,
        daily_breakdown: [
          %{date: ~D[2025-04-01], total: #Decimal<100.00>, count: 2},
          %{date: ~D[2025-04-02], total: #Decimal<150.00>, count: 3},
          ...
        ],
        average_daily_expenditure: #Decimal<83.33>
      }

  """
  def get_monthly_expenditure_report(year, month) when is_integer(year) and is_integer(month) do
    # Calculate the first and last day of the month
    days_in_month = Date.days_in_month(Date.new!(year, month, 1))
    start_date = Date.new!(year, month, 1)
    end_date = Date.new!(year, month, days_in_month)
    
    # Get all expenditures for the month
    expenditures = list_expenditures_by_date_range(start_date, end_date)
    
    # Group expenditures by date
    grouped_expenditures = group_expenditures_by_date(expenditures)
    
    # Create daily breakdown
    daily_breakdown = 
      for day <- 1..days_in_month do
        date = Date.new!(year, month, day)
        day_expenditures = Map.get(grouped_expenditures, date, [])
        day_total = Enum.reduce(day_expenditures, Decimal.new("0.00"), fn expenditure, acc ->
          Decimal.add(acc, expenditure.amount)
        end)
        
        %{
          date: date,
          total: day_total,
          count: length(day_expenditures)
        }
      end
    
    # Calculate monthly totals
    total_expenditures = Enum.reduce(expenditures, Decimal.new("0.00"), fn expenditure, acc ->
      Decimal.add(acc, expenditure.amount)
    end)
    
    expenditure_count = length(expenditures)
    
    # Calculate average daily expenditure
    days_with_expenditures = Enum.count(daily_breakdown, fn day -> day.count > 0 end)
    average_daily_expenditure = 
      if days_with_expenditures > 0 do
        Decimal.div(total_expenditures, Decimal.new(days_with_expenditures))
      else
        Decimal.new("0.00")
      end
    
    %{
      year: year,
      month: month,
      total_expenditures: total_expenditures,
      expenditure_count: expenditure_count,
      daily_breakdown: daily_breakdown,
      average_daily_expenditure: average_daily_expenditure
    }
  end
  @doc """
  Returns the most recent reports for the dashboard.
  
  ## Examples
  
      iex> list_recent_reports(5)
      [%Report{}, ...]
  
  """
  def list_recent_reports(limit \\ 5) do
    query = from r in Report,
            order_by: [desc: r.inserted_at],
            limit: ^limit,
            preload: [:cashing_reports]
    
    reports = Repo.all(query)
    
    # If there are no reports or we need additional cashing reports to reach the limit
    if length(reports) < limit do
      cashing_reports_query = from cr in CashingReport,
                             order_by: [desc: cr.inserted_at],
                             limit: ^(limit - length(reports))
      
      cashing_reports = Repo.all(cashing_reports_query)
      reports ++ cashing_reports
    else
      reports
    end
  end
  
  @doc """
  Returns the most recent transactions for the dashboard.
  
  ## Examples
  
      iex> list_recent_transactions(5)
      [%{id: 1, type: "income", amount: #Decimal<100.00>, inserted_at: ~N[2025-04-06 10:00:00]}, ...]
  
  """
  def list_recent_transactions(limit \\ 5) do
    query = from cr in CashingReport,
            select: %{
              id: cr.id,
              type: "income",
              amount: cr.received_cashing,
              inserted_at: cr.inserted_at
            },
            order_by: [desc: cr.inserted_at],
            limit: ^limit
    
    income_transactions = Repo.all(query)
    
    expenditure_query = from e in Expenditure,
                        select: %{
                          id: e.id,
                          type: "expense",
                          amount: e.amount,
                          inserted_at: e.inserted_at
                        },
                        order_by: [desc: e.inserted_at],
                        limit: ^limit
    
    expense_transactions = Repo.all(expenditure_query)
    
    # Combine and sort both types of transactions by date
    (income_transactions ++ expense_transactions)
    |> Enum.sort_by(fn t -> t.inserted_at end, {:desc, NaiveDateTime})
    |> Enum.take(limit)
  end
  
  @doc """
  Returns the total count of expenditures.
  
  ## Examples
  
      iex> count_expenditures()
      42
  
  """
  def count_expenditures do
    Repo.aggregate(Expenditure, :count, :id)
  end

  # ── PDF Report Queries ────────────────────────────────────────────────────

  def list_cashing_reports_for_date(date) do
    query =
      from cr in CashingReport,
        where: cr.report_date == ^date,
        order_by: [asc: cr.inserted_at],
        preload: [:bus, :conductor, :expenditures]

    Repo.all(query)
  end

  def get_report_with_cashing_details!(id) do
    cashing_preload = [cashing_reports: [:bus, :conductor, :expenditures]]

    Repo.get!(Report, id) |> Repo.preload(cashing_preload)
  end

  def get_cashing_report_with_details!(id) do
    Repo.get!(CashingReport, id) |> Repo.preload([:bus, :conductor, :expenditures, :report])
  end

  def get_expenditures_report(start_date, end_date) do
    expenditures = list_expenditures_by_date_range(start_date, end_date) |> Repo.preload(:cashing_report)
    total = Enum.reduce(expenditures, Decimal.new("0.00"), &Decimal.add(&2, &1.amount))

    by_date =
      expenditures
      |> Enum.group_by(&NaiveDateTime.to_date(&1.date))
      |> Enum.sort_by(fn {date, _} -> date end)
      |> Enum.map(fn {date, items} ->
        day_total = Enum.reduce(items, Decimal.new("0.00"), &Decimal.add(&2, &1.amount))
        %{date: date, items: items, total: day_total}
      end)

    %{expenditures: expenditures, total: total, by_date: by_date}
  end

  def cashing_summary_for_report(report_id) do
    reports = get_cashing_reports_by_report(report_id)

    total_expected = Enum.reduce(reports, Decimal.new("0.00"), &Decimal.add(&2, &1.expected_cashing || Decimal.new(0)))
    total_received = Enum.reduce(reports, Decimal.new("0.00"), &Decimal.add(&2, &1.received_cashing || Decimal.new(0)))
    total_expenditure = Enum.reduce(reports, Decimal.new("0.00"), &Decimal.add(&2, &1.expenditure || Decimal.new(0)))
    total_debt = Enum.reduce(reports, Decimal.new("0.00"), &Decimal.add(&2, &1.debt_balance || Decimal.new(0)))
    variance = Decimal.sub(total_received, total_expected)

    %{
      total_expected: total_expected,
      total_received: total_received,
      total_expenditure: total_expenditure,
      total_debt: total_debt,
      variance: variance,
      count: length(reports)
    }
  end
end
