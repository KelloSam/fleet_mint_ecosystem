defmodule FleetMintWeb.AuditLogController do
  use FleetMintWeb, :controller

  alias FleetMint.Administration

  def index(conn, params) do
    page = FleetMint.Pagination.parse_page(params)

    paged =
      Administration.list_audit_logs_paginated(page,
        organisation_id: conn.assigns.organisation_scope
      )

    today_count = Administration.count_audit_logs_today()
    render(conn, :index, paged: paged, today_count: today_count)
  end
end
