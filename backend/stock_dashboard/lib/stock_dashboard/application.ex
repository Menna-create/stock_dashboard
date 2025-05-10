defmodule StockDashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    finnhub_config = Application.get_env(:stock_dashboard, :finnhub)

    children = [
      StockDashboardWeb.Telemetry,
      StockDashboard.Repo,
      {DNSCluster, query: Application.get_env(:stock_dashboard, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: StockDashboard.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: StockDashboard.Finch},
      # Start a worker by calling: StockDashboard.Worker.start_link(arg)
      # {StockDashboard.Worker, arg},
      # Start to serve requests, typically the last entry
      StockDashboardWeb.Endpoint,
      {StockDashboard.Finnhub, [api_key: finnhub_config[:api_key]]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StockDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StockDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end