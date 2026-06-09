defmodule FleetMintWeb.PageController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Fleet

  def home(conn, _params) do
    render(conn, :home)
  end
  
  def dashboard(conn, _params) do
    current_user = conn.assigns.current_user
    
    # Get summary data for the dashboard
    recent_reports = Finance.list_recent_reports(5)
    recent_transactions = Finance.list_recent_transactions(5)
    
    # Get counts for dashboard stats
    total_buses = Fleet.count_buses()
    total_routes = Fleet.count_routes()
    total_expenditures = Finance.count_expenditures()
    
    render(conn, :dashboard, 
      current_user: current_user,
      recent_reports: recent_reports,
      recent_transactions: recent_transactions,
      total_buses: total_buses,
      total_routes: total_routes,
      total_expenditures: total_expenditures
    )
  end
end
