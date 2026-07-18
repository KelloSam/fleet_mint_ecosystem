defmodule FleetMint.Finance do
  @moduledoc """
  The Finance context.
  """

  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Accounting
  alias FleetMint.Transport.Fleet.Bus
  alias FleetMint.Transport.Trips.{Schedule, Trip}

  alias FleetMint.Finance.{CashingReport, CashingReportTrip}

  @doc """
  Returns the list of cashing_reports.

  ## Examples

      iex> list_cashing_reports()
      [%CashingReport{}, ...]

  """
  def list_cashing_reports(opts \\ []) do
    CashingReport
    |> maybe_filter_cashing_report_organisation(opts[:organisation_id])
    |> Repo.all()
  end

  @doc """
  Gets a single cashing_report.

  Raises if the Cashing report does not exist.

  ## Examples

      iex> get_cashing_report!(123)
      %CashingReport{}

  """
  def get_cashing_report!(id), do: Repo.get!(CashingReport, id) |> Repo.preload(:bus)

  @doc """
  Creates a cashing_report.

  ## Examples

      iex> create_cashing_report(%{field: value})
      {:ok, %CashingReport{}}

      iex> create_cashing_report(%{field: bad_value})
      {:error, ...}

  """
  def create_cashing_report(attrs \\ %{}) do
    changeset = CashingReport.changeset(%CashingReport{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:cashing_report, changeset)
    |> Accounting.multi_insert_entry(:ledger_entry, fn %{cashing_report: cashing_report} ->
      %{
        entry_type: "revenue",
        source_type: "CashingReport",
        source_id: cashing_report.id,
        amount: cashing_report.received_cashing,
        recorded_by_id: cashing_report.conductor_id,
        occurred_at: DateTime.new!(cashing_report.report_date, ~T[00:00:00]),
        description: "Cash received for report #{cashing_report.report_date}"
      }
    end)
    |> Ecto.Multi.merge(fn %{cashing_report: cashing_report} -> trip_match_multi(cashing_report) end)
    |> Repo.transaction()
    |> unwrap_multi(:cashing_report_reconciled)
  end

  @doc """
  Attempts to attribute a CashingReport's cash to a single Trip, without
  ever fabricating one. Only classifies — inserting the resulting
  cashing_report_trips row (for `:automatically_matched`) and updating the
  report's `trip_mapping_status` is the caller's job (see `create_cashing_report/1`
  and `trip_match_multi/1`).

  Returns one of:

    * `{:automatically_matched, %Trip{}, organisation_id}` — exactly one
      same-organisation schedule has ever used this bus's vehicle, and a
      Trip already exists for that schedule on this report's date.
    * `{:ambiguous, notes}` — more than one same-organisation schedule
      shares the vehicle; a human has to pick.
    * `{:unmappable, notes}` — no candidate exists at all (missing bus,
      missing vehicle assignment, no schedule, cross-organisation vehicle
      sharing, or no Trip recorded yet for that date).
  """
  def attempt_trip_match(%CashingReport{bus_id: nil}) do
    {:unmappable, "No bus recorded on this report."}
  end

  def attempt_trip_match(%CashingReport{} = cashing_report) do
    bus = Repo.get!(Bus, cashing_report.bus_id)

    cond do
      is_nil(bus.vehicle_id) ->
        {:unmappable, "Bus has no vehicle assignment recorded."}

      true ->
        classify_by_candidate_schedules(cashing_report, bus)
    end
  end

  defp classify_by_candidate_schedules(cashing_report, bus) do
    candidates =
      from(s in Schedule,
        join: op in assoc(s, :operator),
        where: s.vehicle_id == ^bus.vehicle_id,
        select: {s.id, op.organisation_id}
      )
      |> Repo.all()

    same_org_candidates = Enum.filter(candidates, fn {_schedule_id, org_id} -> org_id == bus.organisation_id end)

    case {candidates, same_org_candidates} do
      {[], _} ->
        {:unmappable, "No schedule has ever been assigned this vehicle."}

      {_, []} ->
        {:unmappable,
         "Vehicle is only used on schedules belonging to a different organisation than the bus record - data integrity issue, flagged for manual review."}

      {_, [{schedule_id, organisation_id}]} ->
        case Repo.get_by(Trip, schedule_id: schedule_id, travel_date: cashing_report.report_date) do
          nil ->
            {:unmappable,
             "A single schedule was found for this vehicle, but no trip is recorded for that schedule on this report date."}

          %Trip{} = trip ->
            {:automatically_matched, trip, organisation_id}
        end

      {_, _multiple} ->
        {:ambiguous,
         "Vehicle is assigned to more than one schedule in this organisation; automatic matching cannot determine which trip this cash belongs to. Needs manual reconciliation."}
    end
  end

  defp trip_match_multi(cashing_report) do
    case attempt_trip_match(cashing_report) do
      {:automatically_matched, trip, organisation_id} ->
        allocation_changeset =
          CashingReportTrip.changeset(%CashingReportTrip{}, %{
            cashing_report_id: cashing_report.id,
            trip_id: trip.id,
            organisation_id: organisation_id,
            allocated_amount: cashing_report.received_cashing,
            match_method: "automatic",
            matched_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:trip_allocation, allocation_changeset)
        |> Ecto.Multi.update(
          :cashing_report_reconciled,
          CashingReport.mapping_status_changeset(cashing_report, %{
            trip_mapping_status: "automatically_matched",
            trip_mapping_notes: "Matched to a single trip via bus/vehicle/schedule chain."
          })
        )

      {status, notes} ->
        Ecto.Multi.new()
        |> Ecto.Multi.update(
          :cashing_report_reconciled,
          CashingReport.mapping_status_changeset(cashing_report, %{
            trip_mapping_status: Atom.to_string(status),
            trip_mapping_notes: notes
          })
        )
    end
  end

  @doc """
  Manually attributes a CashingReport's cash to a Trip — the reconciliation
  path for reports `attempt_trip_match/1` classified as `:ambiguous` or
  `:unmappable`. Rejects the match (without touching either record) if the
  report's bus and the Trip belong to different organisations; this can't
  be a database-level composite FK the way Trip's own children can, since
  CashingReport has no organisation_id column of its own, so it's enforced
  here instead.
  """
  def match_cashing_report_to_trip(%CashingReport{} = cashing_report, %Trip{} = trip, matched_by_user, opts \\ []) do
    bus = cashing_report.bus_id && Repo.get(Bus, cashing_report.bus_id)

    cond do
      is_nil(bus) ->
        {:error, :no_bus_on_report}

      bus.organisation_id != trip.organisation_id ->
        {:error, :organisation_mismatch}

      true ->
        amount = Keyword.get(opts, :allocated_amount, cashing_report.received_cashing)

        allocation_changeset =
          CashingReportTrip.changeset(%CashingReportTrip{}, %{
            cashing_report_id: cashing_report.id,
            trip_id: trip.id,
            organisation_id: trip.organisation_id,
            allocated_amount: amount,
            match_method: "manual",
            matched_at: DateTime.utc_now() |> DateTime.truncate(:second),
            matched_by_id: matched_by_user.id
          })

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:trip_allocation, allocation_changeset)
        |> Ecto.Multi.update(
          :cashing_report_reconciled,
          CashingReport.mapping_status_changeset(cashing_report, %{
            trip_mapping_status: "manually_matched",
            trip_mapping_notes: "Manually matched by user ##{matched_by_user.id}."
          })
        )
        |> Repo.transaction()
        |> unwrap_multi(:cashing_report_reconciled)
    end
  end

  @doc """
  Reports not yet attributed to a Trip — `:pending` (not yet attempted),
  `:ambiguous`, or `:unmappable`. This is the reconciliation work queue;
  `:automatically_matched` and `:manually_matched` reports are excluded.
  """
  def list_unreconciled_cashing_reports(opts \\ []) do
    CashingReport
    |> where([c], c.trip_mapping_status in ["pending", "ambiguous", "unmappable"])
    |> maybe_filter_cashing_report_organisation(opts[:organisation_id])
    |> Repo.all()
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
    changeset = CashingReport.changeset(cashing_report, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:cashing_report, changeset)
    |> Ecto.Multi.run(:ledger_entry, fn _repo, %{cashing_report: updated} ->
      case Accounting.entries_for_source("CashingReport", updated.id, "revenue") do
        [entry] ->
          entry
          |> Accounting.change_entry(%{
            amount: updated.received_cashing,
            recorded_by_id: updated.conductor_id,
            occurred_at: DateTime.new!(updated.report_date, ~T[00:00:00])
          })
          |> Repo.update()

        [] ->
          {:ok, nil}
      end
    end)
    |> Repo.transaction()
    |> unwrap_multi(:cashing_report)
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
  def list_expenditures(opts \\ []) do
    from(e in Expenditure, order_by: [desc: e.date])
    |> maybe_filter_expenditure_organisation(opts[:organisation_id])
    |> Repo.all()
  end

  @doc """
  Gets a single expenditure.

  Raises if the Expenditure does not exist.

  ## Examples

      iex> get_expenditure!(123)
      %Expenditure{}

  """
  def get_expenditure!(id), do: Repo.get!(Expenditure, id) |> Repo.preload(cashing_report: :bus)

  @doc """
  Creates a expenditure.

  ## Examples

      iex> create_expenditure(%{field: value})
      {:ok, %Expenditure{}}

      iex> create_expenditure(%{field: bad_value})
      {:error, ...}

  """
  def create_expenditure(attrs \\ %{}) do
    changeset = Expenditure.changeset(%Expenditure{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:expenditure, changeset)
    |> Accounting.multi_insert_entry(:ledger_entry, fn %{expenditure: expenditure} ->
      %{
        entry_type: "expense",
        source_type: "Expenditure",
        source_id: expenditure.id,
        amount: expenditure.amount,
        occurred_at: DateTime.from_naive!(expenditure.date, "Etc/UTC"),
        description: expenditure.description
      }
    end)
    |> Repo.transaction()
    |> unwrap_multi(:expenditure)
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
    changeset = Expenditure.changeset(expenditure, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:expenditure, changeset)
    |> Ecto.Multi.run(:ledger_entry, fn _repo, %{expenditure: updated} ->
      case Accounting.entries_for_source("Expenditure", updated.id, "expense") do
        [entry] ->
          entry
          |> Accounting.change_entry(%{
            amount: updated.amount,
            description: updated.description,
            occurred_at: DateTime.from_naive!(updated.date, "Etc/UTC")
          })
          |> Repo.update()

        [] ->
          {:ok, nil}
      end
    end)
    |> Repo.transaction()
    |> unwrap_multi(:expenditure)
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
    from(r in Report,
      order_by: [desc: r.inserted_at],
      limit: ^limit,
      preload: [:cashing_reports]
    ) |> Repo.all()
  end
  
  @doc """
  Returns the most recent transactions for the dashboard.
  
  ## Examples
  
      iex> list_recent_transactions(5)
      [%{id: 1, type: "income", amount: #Decimal<100.00>, inserted_at: ~N[2025-04-06 10:00:00]}, ...]
  
  """
  def list_recent_transactions(limit \\ 5) do
    Accounting.list_entries()
    |> Enum.take(limit)
    |> Enum.map(fn entry ->
      %{
        id: entry.id,
        type: if(entry.entry_type == "revenue", do: "income", else: entry.entry_type),
        amount: entry.amount,
        inserted_at: entry.inserted_at
      }
    end)
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

  # ── Private ───────────────────────────────────────────────────────────────

  defp unwrap_multi(multi_result, ok_key) do
    case multi_result do
      {:ok, changes} -> {:ok, Map.fetch!(changes, ok_key)}
      {:error, _failed_step, failed_value, _changes} -> {:error, failed_value}
    end
  end

  defp maybe_filter_cashing_report_organisation(query, nil), do: query
  defp maybe_filter_cashing_report_organisation(query, :all), do: query
  defp maybe_filter_cashing_report_organisation(query, organisation_id) do
    query
    |> join(:inner, [c], b in assoc(c, :bus), as: :bus)
    |> where([bus: b], b.organisation_id == ^organisation_id)
  end

  defp maybe_filter_expenditure_organisation(query, nil), do: query
  defp maybe_filter_expenditure_organisation(query, :all), do: query
  defp maybe_filter_expenditure_organisation(query, organisation_id) do
    query
    |> join(:inner, [e], c in assoc(e, :cashing_report), as: :cashing_report)
    |> join(:inner, [cashing_report: c], b in assoc(c, :bus), as: :bus)
    |> where([bus: b], b.organisation_id == ^organisation_id)
  end
end
