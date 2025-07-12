defmodule BusCashingSystem.Repo do
  use Ecto.Repo,
    otp_app: :bus_cashing_system,
    adapter: Ecto.Adapters.Postgres
end
