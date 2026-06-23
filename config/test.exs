import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :fleet_mint, FleetMint.Repo,
  username: "think",
  password: "password1",
  hostname: "localhost",
  database: "fleet_mint_test#{System.get_env("MIX_TEST_PARTITION")}",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :fleet_mint, FleetMintWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+zBuQA4qU2n86d0j6+IMSW/M8dUi8R9OHlVc6zjP35w6X6XFaoth+g3v2hi8JZl8",
  server: false

# In test we don't send emails
config :fleet_mint, FleetMint.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :fleet_mint, :qr_secret, "test_only_qr_secret"
