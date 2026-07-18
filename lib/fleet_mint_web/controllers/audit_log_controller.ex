defmodule FleetMintWeb.AuditLogController do
  use FleetMintWeb, :controller

  alias FleetMint.Administration

  def index(conn, _params) do
    logs = Administration.list_recent_audit_logs(200, organisation_id: conn.assigns.organisation_scope)
    today_count = Administration.count_audit_logs_today()
    render(conn, :index, logs: logs, today_count: today_count)
  end
end
