defmodule FleetMint.Operations do
  import Ecto.Query, warn: false
  alias FleetMint.Repo

  # ── Drivers ───────────────────────────────────────────────────────────────

  alias FleetMint.Operations.Driver

  def list_drivers do
    from(d in Driver, where: is_nil(d.archived_at), order_by: d.name)
    |> preload(:user)
    |> Repo.all()
  end

  def list_active_drivers do
    from(d in Driver, where: d.status == "active" and is_nil(d.archived_at), order_by: d.name)
    |> preload(:user)
    |> Repo.all()
  end

  def get_driver!(id), do: Driver |> preload(:user) |> Repo.get!(id)

  def create_driver(attrs \\ %{}) do
    %Driver{} |> Driver.changeset(attrs) |> Repo.insert()
  end

  def update_driver(%Driver{} = driver, attrs) do
    driver |> Driver.changeset(attrs) |> Repo.update()
  end

  def delete_driver(%Driver{} = driver) do
    driver
    |> Ecto.Changeset.change(archived_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    |> Repo.update()
  end

  def change_driver(%Driver{} = driver, attrs \\ %{}), do: Driver.changeset(driver, attrs)

  def count_drivers, do: Repo.aggregate(Driver, :count, :id)

  def count_active_drivers do
    Repo.aggregate(from(d in Driver, where: d.status == "active"), :count)
  end

  def list_drivers_with_expiring_licenses(days \\ 30) do
    cutoff = Date.add(Date.utc_today(), days)
    today = Date.utc_today()
    from(d in Driver,
      where: not is_nil(d.license_expiry) and d.license_expiry >= ^today and d.license_expiry <= ^cutoff,
      order_by: d.license_expiry)
    |> Repo.all()
  end

  # ── Operation Logs ────────────────────────────────────────────────────────

  alias FleetMint.Operations.OperationLog

  def list_operation_logs do
    OperationLog |> order_by([l], desc: l.date) |> preload(:logged_by) |> Repo.all()
  end

  def list_recent_logs(limit \\ 10) do
    OperationLog
    |> order_by([l], desc: l.date, desc: l.inserted_at)
    |> limit(^limit)
    |> preload(:logged_by)
    |> Repo.all()
  end

  def list_logs_for_date(date) do
    from(l in OperationLog, where: l.date == ^date, order_by: [desc: l.inserted_at])
    |> preload(:logged_by)
    |> Repo.all()
  end

  def get_operation_log!(id), do: OperationLog |> preload(:logged_by) |> Repo.get!(id)

  def create_operation_log(attrs \\ %{}) do
    %OperationLog{} |> OperationLog.changeset(attrs) |> Repo.insert()
  end

  def update_operation_log(%OperationLog{} = log, attrs) do
    log |> OperationLog.changeset(attrs) |> Repo.update()
  end

  def delete_operation_log(%OperationLog{} = log), do: Repo.delete(log)

  def change_operation_log(%OperationLog{} = log, attrs \\ %{}),
    do: OperationLog.changeset(log, attrs)
end
