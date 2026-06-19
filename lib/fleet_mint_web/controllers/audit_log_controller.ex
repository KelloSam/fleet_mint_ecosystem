defmodule FleetMintWeb.AuditLogController do
  use FleetMintWeb, :controller

  alias FleetMint.AuditLogs

  def index(conn, _params) do
    logs = AuditLogs.list_recent(200)
    today_count = AuditLogs.count_today()
    render(conn, :index, logs: logs, today_count: today_count)
  end
end
