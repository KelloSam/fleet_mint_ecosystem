defmodule FleetMint.Repo do
  use Ecto.Repo,
    otp_app: :fleet_mint,
    adapter: Ecto.Adapters.Postgres
end
