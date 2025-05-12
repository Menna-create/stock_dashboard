defmodule StockDashboard.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    finnhub_config = Application.get_env(:stock_dashboard, :finnhub)

    children = [
      # Start the Telemetry supervisor
      StockDashboardWeb.Telemetry,
      # Start the Ecto repository
      StockDashboard.Repo,
      # Start the DNS cluster monitor
      {DNSCluster, query: Application.get_env(:stock_dashboard, :dns_cluster_query) || :ignore},
      # Start Phoenix PubSub system
      {Phoenix.PubSub, name: StockDashboard.PubSub},
      # Start Finch HTTP client
      {Finch, name: StockDashboard.Finch},
      # Start the Phoenix endpoint
      StockDashboardWeb.Endpoint,
      # Start Finnhub client
      {StockDashboard.Finnhub, [api_key: finnhub_config[:api_key]]},
     
    ]

    opts = [strategy: :one_for_one, name: StockDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    StockDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end 