defmodule FleetMint.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FleetMintWeb.Telemetry,
      FleetMint.Repo,
      {DNSCluster, query: Application.get_env(:fleet_mint, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FleetMint.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: FleetMint.Finch},
      {ChromicPDF, chromic_pdf_opts()},
      FleetMintWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FleetMint.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FleetMintWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp chromic_pdf_opts do
    [
      chrome_executable: System.find_executable("google-chrome") || System.find_executable("chromium-browser"),
      no_sandbox: true,
      offline: true
    ]
  end
end
