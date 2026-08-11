defmodule FleetMintWeb.ReconciliationController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance.Reconciliation

  def index(conn, params) do
    date =
      case params["date"] && Date.from_iso8601(params["date"]) do
        {:ok, d} -> d
        _ -> Date.utc_today()
      end

    scope = conn.assigns.organisation_scope

    render(conn, :index,
      date: date,
      minibus_variances: Reconciliation.minibus_variance_for_date(date, scope),
      intercity_collections: Reconciliation.intercity_collections_for_date(date, scope),
      freight_aging: Reconciliation.freight_invoice_aging(scope)
    )
  end
end
