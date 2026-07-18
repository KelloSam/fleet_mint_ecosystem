defmodule FleetMintWeb.Router do
  use FleetMintWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FleetMintWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; " <>
        "script-src 'self' 'unsafe-inline'; " <>
        "style-src 'self' 'unsafe-inline'; " <>
        "img-src 'self' data: blob:; " <>
        "connect-src 'self' ws: wss:; " <>
        "frame-ancestors 'self'; " <>
        "base-uri 'self'; " <>
        "form-action 'self';"
    }
  end
  
  pipeline :auth do
    plug FleetMintWeb.Plugs.AuthPlug
    plug FleetMintWeb.Plugs.TenantScopePlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_manager do
    plug FleetMintWeb.Plugs.RequireRolePlug, roles: ["platform_admin", "tenant_admin", "manager"]
  end

  # Either admin tier may reach /users - UserController itself scopes a
  # tenant_admin to their own organisation and blocks them from creating
  # or promoting anyone to platform_admin. Not the same gate as
  # :require_platform_admin below.
  pipeline :require_admin do
    plug FleetMintWeb.Plugs.RequireRolePlug, roles: ["platform_admin", "tenant_admin"]
  end

  # The full, platform-wide audit trail - a tenant administrator must not
  # see other tenants' (or Miway's own) security events, so this is
  # platform_admin only, unlike :require_admin above.
  pipeline :require_platform_admin do
    plug FleetMintWeb.Plugs.RequireRolePlug, roles: ["platform_admin"]
  end

  pipeline :rate_limited do
    plug FleetMintWeb.Plugs.RateLimitPlug
  end

  # Rate-limited routes (login POST only)
  scope "/", FleetMintWeb do
    pipe_through [:browser, :rate_limited]

    post "/login", AuthController, :authenticate
  end

  # Public routes - no authentication required
  scope "/", FleetMintWeb do
    pipe_through :browser

    # Authentication routes
    get "/login", AuthController, :login
    get "/register", AuthController, :register
    post "/register", AuthController, :create
    delete "/logout", AuthController, :logout
    get  "/login/verify", TwoFactorController, :verify
    post "/login/verify", TwoFactorController, :confirm

    # Password reset (public)
    get  "/password-reset",        PasswordResetController, :new
    post "/password-reset",        PasswordResetController, :create
    get  "/password-reset/:token", PasswordResetController, :edit
    put  "/password-reset/:token", PasswordResetController, :update

    # Home page accessible without login
    get "/", PageController, :home

    # Public client booking portal
    get  "/book",                          PublicBookingController, :index
    get  "/book/ticket/:reference",        PublicBookingController, :ticket
    get  "/book/:slug",                    PublicBookingController, :show
    get  "/book/:slug/:schedule_id",       PublicBookingController, :book
    post "/book/:slug/:schedule_id",       PublicBookingController, :create

    # Public bus / parcel tracking
    get  "/track",                         TrackingController, :index

    # Public passenger feedback (complaint + suggestion box)
    get  "/feedback/new",                  ComplaintController, :new
    post "/feedback",                      ComplaintController, :create
    get  "/feedback/thank_you",            ComplaintController, :thank_you
  end
  
  # Manager and admin — fleet management, freight, financial reports
  #
  # Declared BEFORE the "all authenticated users" scope below on purpose:
  # Phoenix matches routes in file-declaration order across all scopes, and
  # several resources here are split into a manager+ write half (this scope,
  # `except: [:index, :show]`) and a cashier+ read-only half (`only: [:index,
  # :show]`, next scope). If the read-only `/:id` route were declared first,
  # it would swallow `/new` (id="new") before reaching this scope's `new`
  # action — reordering the scopes fixes that for every split resource at
  # once without changing any pipeline/permission behavior.
  scope "/", FleetMintWeb do
    pipe_through [:browser, :auth, :require_manager]

    resources "/reports", ReportController
    get "/reconciliation", ReconciliationController, :index

    # Fleet write access (create, edit, update, delete)
    resources "/vehicles", VehicleController, except: [:index, :show]
    resources "/maintenances", VehicleMaintenanceController, except: [:index, :show]
    resources "/drivers", DriverController, except: [:index, :show]
    resources "/routes", RouteController, except: [:index, :show]
    resources "/schedules", ScheduleController, except: [:index, :show]
    resources "/operators", OperatorController, except: [:index, :show]
    resources "/buses", BusController, except: [:index, :show]

    # Freight management
    scope "/freight" do
      resources "/clients", FreightClientController
      resources "/orders", FreightOrderController
      resources "/trips", FreightTripController do
        post "/milestones", FreightTripController, :add_milestone
        patch "/status", FreightTripController, :update_status
      end
      resources "/invoices", FreightInvoiceController
    end

    # PDF and financial reports
    get "/admin/reports",    PdfReportController, :index
    get "/pdf/daily",        PdfReportController, :daily
    get "/pdf/weekly/:id",   PdfReportController, :weekly
    get "/pdf/receipt/:id",  PdfReportController, :receipt
    get "/pdf/expenditures", PdfReportController, :expenditures
  end

  # All authenticated users (cashier and above)
  scope "/", FleetMintWeb do
    pipe_through [:browser, :auth]

    get "/dashboard", PageController, :dashboard

    # Cashier-owned resources — full CRUD
    # Declared before the resources macro below so "unmatched" isn't
    # swallowed by the :id-shaped show route (same ordering concern noted
    # at the top of this file for :new).
    get  "/cashing_reports/unmatched",        CashingReportController, :unmatched
    resources "/cashing_reports", CashingReportController
    get  "/cashing_reports/:id/trip_match",   CashingReportController, :edit_trip_match
    post "/cashing_reports/:id/trip_match",   CashingReportController, :match_trip
    resources "/expenditures", ExpenditureController
    resources "/bookings", BookingController
    resources "/operation_logs", OperationLogController
    resources "/fuel_logs", FuelLogController
    resources "/minibus_trips", MinibusTripController

    # Tickets: view and validate only
    resources "/tickets", TicketController, only: [:index, :show]
    get "/tickets/:id/validate", TicketController, :validate

    # Fleet: read-only for cashiers and operators
    resources "/vehicles", VehicleController, only: [:index, :show]
    resources "/maintenances", VehicleMaintenanceController, only: [:index, :show]
    resources "/drivers", DriverController, only: [:index, :show]
    resources "/routes", RouteController, only: [:index, :show]
    resources "/schedules", ScheduleController, only: [:index, :show]
    resources "/operators", OperatorController, only: [:index, :show]
    resources "/buses", BusController, only: [:index, :show]

    # Bus GPS checkpoint (posted by on-duty staff)
    post "/schedules/:id/checkpoint", ScheduleController, :post_checkpoint

    # Complaints management (all staff)
    resources "/complaints", ComplaintController, only: [:index, :show, :update, :delete]

    # Internal JSON API
    get "/api/notifications", ApiController, :notifications
    get "/api/seats", ApiController, :available_seats

    # 2FA settings
    get    "/settings/2fa",         TwoFactorController, :setup
    post   "/settings/2fa/enable",  TwoFactorController, :enable
    delete "/settings/2fa/disable", TwoFactorController, :disable
  end

  # Platform administrators only - the full, platform-wide audit trail.
  scope "/", FleetMintWeb do
    pipe_through [:browser, :auth, :require_platform_admin]

    get "/audit-log", AuditLogController, :index
  end

  # Either admin tier - UserController scopes a tenant_admin to their own
  # organisation's users internally (see with_organisation_access there).
  scope "/", FleetMintWeb do
    pipe_through [:browser, :auth, :require_admin]

    resources "/users", UserController, except: [:delete]
    post "/users/:id/activate",   UserController, :activate
    post "/users/:id/deactivate", UserController, :deactivate
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
