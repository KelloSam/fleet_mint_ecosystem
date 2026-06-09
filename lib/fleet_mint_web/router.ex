defmodule FleetMintWeb.Router do
  use FleetMintWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FleetMintWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  
  pipeline :auth do
    plug FleetMintWeb.Plugs.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes - no authentication required
  scope "/", FleetMintWeb do
    pipe_through :browser

    # Authentication routes
    get "/login", AuthController, :login
    post "/login", AuthController, :authenticate
    get "/register", AuthController, :register
    post "/register", AuthController, :create
    delete "/logout", AuthController, :logout
    
    # Home page accessible without login
    get "/", PageController, :home
  end
  
  # Protected routes - authentication required
  scope "/", FleetMintWeb do
    pipe_through [:browser, :auth]
    
    # Dashboard will be the main entry point after login
    get "/dashboard", PageController, :dashboard
    
    # Protected resources
    resources "/reports", ReportController
    resources "/cashing_reports", CashingReportController
    resources "/expenditures", ExpenditureController
    resources "/buses", BusController
    resources "/routes", RouteController

    # Unified vehicle fleet (buses + trucks)
    resources "/vehicles", VehicleController

    # Transit (passenger)
    resources "/schedules", ScheduleController
    resources "/bookings", BookingController
    resources "/tickets", TicketController, only: [:index, :show]
    get "/tickets/:id/validate", TicketController, :validate

    # Freight (haulage)
    scope "/freight" do
      resources "/clients", FreightClientController
      resources "/orders", FreightOrderController
      resources "/trips", FreightTripController do
        post "/milestones", FreightTripController, :add_milestone
        patch "/status", FreightTripController, :update_status
      end
      resources "/invoices", FreightInvoiceController
    end

    # Admin reports hub
    get "/admin/reports", PdfReportController, :index

    # PDF download endpoints (open in new tab → browser saves PDF)
    get "/pdf/daily", PdfReportController, :daily
    get "/pdf/weekly/:id", PdfReportController, :weekly
    get "/pdf/receipt/:id", PdfReportController, :receipt
    get "/pdf/expenditures", PdfReportController, :expenditures
  end

  # Other scopes may use custom stacks.
  # scope "/api", FleetMintWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:fleet_mint, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FleetMintWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
