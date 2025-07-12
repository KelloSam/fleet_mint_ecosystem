defmodule BusCashingSystemWeb.Router do
  use BusCashingSystemWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BusCashingSystemWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  
  pipeline :auth do
    plug BusCashingSystemWeb.Plugs.AuthPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes - no authentication required
  scope "/", BusCashingSystemWeb do
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
  scope "/", BusCashingSystemWeb do
    pipe_through [:browser, :auth]
    
    # Dashboard will be the main entry point after login
    get "/dashboard", PageController, :dashboard
    
    # Protected resources
    resources "/reports", ReportController
    resources "/cashing_reports", CashingReportController
    resources "/expenditures", ExpenditureController
  end

  # Other scopes may use custom stacks.
  # scope "/api", BusCashingSystemWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bus_cashing_system, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BusCashingSystemWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
