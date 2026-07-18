defmodule FleetMint.Administration do
  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Administration.{OperationLog, AuditLog, Complaint}

  # ── Operation Logs ────────────────────────────────────────────────────────

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

  # ── Audit Logs ────────────────────────────────────────────────────────────

  def log(event, opts \\ []) do
    attrs = %{
      event:           event,
      actor_id:        opts[:actor_id],
      actor_email:     opts[:actor_email],
      target_type:     opts[:target_type],
      target_id:       opts[:target_id] && to_string(opts[:target_id]),
      metadata:        opts[:metadata] || %{},
      ip_address:      opts[:ip_address],
      organisation_id: Keyword.get_lazy(opts, :organisation_id, fn -> actor_organisation_id(opts[:actor_id]) end)
    }

    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()

    :ok
  end

  defp actor_organisation_id(nil), do: nil
  defp actor_organisation_id(actor_id), do: Repo.get(FleetMint.Identity.User, actor_id) |> then(& &1 && &1.organisation_id)

  @doc """
  `organisation_id` opt: `:all`/`nil` for a platform administrator (the
  full platform-wide audit trail); an organisation_id scopes to that
  organisation's own events only, per `/audit-log` being platform_admin-
  only for now (see AuditLogController) - this filter exists so a
  tenant-facing audit view is a query-level change away, not a redesign,
  whenever that's built.
  """
  def list_recent_audit_logs(limit \\ 100, opts \\ []) do
    from(l in AuditLog, order_by: [desc: l.inserted_at], limit: ^limit)
    |> maybe_filter_audit_log_organisation(opts[:organisation_id])
    |> Repo.all()
  end

  defp maybe_filter_audit_log_organisation(query, nil), do: query
  defp maybe_filter_audit_log_organisation(query, :all), do: query
  defp maybe_filter_audit_log_organisation(query, organisation_id) do
    where(query, [l], l.organisation_id == ^organisation_id)
  end

  def count_audit_logs_today do
    today_start = NaiveDateTime.new!(Date.utc_today(), ~T[00:00:00])
    from(l in AuditLog, where: l.inserted_at >= ^today_start)
    |> Repo.aggregate(:count)
  end

  # ── Complaints / Feedback ─────────────────────────────────────────────────

  def list_complaints(opts \\ []) do
    Complaint
    |> maybe_filter_type(opts[:type])
    |> maybe_filter_status(opts[:status])
    |> order_by([c], desc: c.inserted_at)
    |> preload(:reviewed_by)
    |> Repo.all()
  end

  def get_complaint!(id), do: Repo.get!(Complaint, id) |> Repo.preload(:reviewed_by)

  def create_complaint(attrs \\ %{}) do
    %Complaint{} |> Complaint.changeset(attrs) |> Repo.insert()
  end

  def update_complaint(%Complaint{} = complaint, attrs) do
    complaint |> Complaint.changeset(attrs) |> Repo.update()
  end

  def delete_complaint(%Complaint{} = complaint), do: Repo.delete(complaint)

  def change_complaint(%Complaint{} = complaint, attrs \\ %{}),
    do: Complaint.changeset(complaint, attrs)

  def count_pending_complaints do
    Repo.aggregate(from(c in Complaint, where: c.status == "pending"), :count)
  end

  defp maybe_filter_type(query, nil), do: query
  defp maybe_filter_type(query, type), do: where(query, [c], c.type == ^type)

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [c], c.status == ^status)
end
