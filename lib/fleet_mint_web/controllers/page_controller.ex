defmodule FleetMintWeb.PageController do
  use FleetMintWeb, :controller

  alias FleetMint.Finance
  alias FleetMint.Transport.Fleet
  alias FleetMint.Transport.Routes
  alias FleetMint.Identity.Users
  alias FleetMint.Transport.Trips
  alias FleetMint.Transport.Ticketing

  plug :put_layout, [html: {FleetMintWeb.Layouts, :public}] when action in [:home]

  def home(conn, _params) do
    if FleetMintWeb.Plugs.AuthPlug.logged_in?(conn) do
      redirect(conn, to: ~p"/dashboard")
    else
      render(conn, :home)
    end
  end

  def dashboard(conn, _params) do
    current_user = conn.assigns.current_user
    org_scope = conn.assigns.organisation_scope

    weekly_revenue_trend = Finance.weekly_revenue_trend(org_scope, 6)
    total_buses = Fleet.count_buses(org_scope)
    total_routes = Routes.count_routes()
    total_vehicles = Fleet.count_vehicles(org_scope)
    total_expenditures = Finance.count_expenditures(org_scope)
    on_duty = Users.list_on_duty_staff(organisation_id: org_scope)
    bookings_today = Ticketing.count_bookings_today(org_scope)
    revenue_today = Ticketing.revenue_today(org_scope)
    trips_today = Trips.count_minibus_trips_today(org_scope)
    minibus_revenue_today = Trips.minibus_revenue_today(org_scope)
    pending_maintenances = Fleet.count_pending_maintenances(org_scope)
    fuel_cost_today = Fleet.fuel_cost_today(org_scope)

    render(conn, :dashboard,
      current_user: current_user,
      weekly_revenue_trend: weekly_revenue_trend,
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
