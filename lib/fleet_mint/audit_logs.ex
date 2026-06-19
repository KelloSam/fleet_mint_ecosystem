defmodule FleetMint.AuditLogs do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.AuditLogs.AuditLog

  def log(event, opts \\ []) do
    attrs = %{
      event:       event,
      actor_id:    opts[:actor_id],
      actor_email: opts[:actor_email],
      target_type: opts[:target_type],
      target_id:   opts[:target_id] && to_string(opts[:target_id]),
      metadata:    opts[:metadata] || %{},
      ip_address:  opts[:ip_address]
    }

    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()

    :ok
  end

  def list_recent(limit \\ 100) do
    from(l in AuditLog, order_by: [desc: l.inserted_at], limit: ^limit)
    |> Repo.all()
  end

  def count_today do
    today_start = NaiveDateTime.new!(Date.utc_today(), ~T[00:00:00])
    from(l in AuditLog, where: l.inserted_at >= ^today_start)
    |> Repo.aggregate(:count)
  end
end
