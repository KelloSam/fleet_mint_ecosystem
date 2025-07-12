import Config

# General application configuration
config :bus_cashing_system,
  ecto_repos: [BusCashingSystem.Repo], # Defines the repository for Ecto.
  generators: [timestamp_type: :utc_datetime]

config :bus_cashing_system, BusCashingSystemWeb.Gettext,
  locales: ~w(en), # List of available locales
  default_locale: "en" # Default locale for the application

# Configures the endpoint
config :bus_cashing_system, BusCashingSystemWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BusCashingSystemWeb.ErrorHTML, json: BusCashingSystemWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BusCashingSystem.PubSub,
  live_view: [signing_salt: "GlXBSlTk"]

# Configures the mailer
#
# By default, it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser at "/dev/mailbox".
#
# For production, configure a different adapter in `config/runtime.exs`.
config :bus_cashing_system, BusCashingSystem.Mailer,
  adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  bus_cashing_system: [ # Ensure the profile key matches your project name
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  bus_cashing_system: [ # Ensure the profile key matches your project name
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Guardian for authentication
config :bus_cashing_system, BusCashingSystem.Auth.Guardian,
  issuer: "bus_cashing_system",
  secret_key: "nHDcHCXpAZE/t4RKMB11xSapxxBBd6l0Zng1Xnk3LsC9VCIYoNUKfouY9Eo6cG51"

# Import environment-specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
