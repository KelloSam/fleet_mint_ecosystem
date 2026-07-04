defmodule FleetMintWeb.PageController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Transport.Fleet
  alias FleetMint.Identity
  alias FleetMint.Transit

  def home(conn, _params) do
    if FleetMintWeb.Plugs.AuthPlug.logged_in?(conn) do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :home)
    end
  end

  def dashboard(conn, _params) do
    current_user = conn.assigns.current_user

    recent_reports = Finance.list_recent_reports(5)
    recent_transactions = Finance.list_recent_transactions(5)
    total_buses = Fleet.count_buses()
    total_routes = Fleet.count_routes()
    total_vehicles = Fleet.count_vehicles()
    total_expenditures = Finance.count_expenditures()
    on_duty = Identity.list_on_duty_staff()
    bookings_today = Transit.count_bookings_today()
    revenue_today = Transit.revenue_today()
    trips_today = Transit.count_minibus_trips_today()
    minibus_revenue_today = Transit.minibus_revenue_today()
    pending_maintenances = Fleet.count_pending_maintenances()
    fuel_cost_today = Fleet.fuel_cost_today()

    render(conn, :dashboard,
      current_user: current_user,
      recent_reports: recent_reports,
      recent_transactions: recent_transactions,
      total_buses: total_buses,
      total_routes: total_routes,
      total_vehicles: total_vehicles,
      total_expenditures: total_expenditures,
      on_duty: on_duty,
      bookings_today: bookings_today,
      revenue_today: revenue_today,
      trips_today: trips_today,
      minibus_revenue_today: minibus_revenue_today,
      pending_maintenances: pending_maintenances,
      fuel_cost_today: fuel_cost_today
    )
  end
end
