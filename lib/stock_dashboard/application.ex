defmodule StockDashboard.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      StockDashboardWeb.Telemetry,
      # Start the Ecto repository
      StockDashboard.Repo,
      # Start DNS cluster for distributed Phoenix
      {DNSCluster, query: Application.get_env(:stock_dashboard, :dns_cluster_query) || :ignore},
      # Start Phoenix PubSub system
      {Phoenix.PubSub, name: StockDashboard.PubSub},
      # Start Finch HTTP client for external requests
      {Finch, name: StockDashboard.Finch},

      # Use Finnhub for WebSocket connection and stock data management
      StockDashboard.Finnhub,
      
      # Start the Phoenix endpoint (must be last)
      StockDashboardWeb.Endpoint
    ]
    |> Enum.reject(&is_nil/1) # Remove any nil children

    # Configure supervisor options
    opts = [
      strategy: :one_for_one,
      name: StockDashboard.Supervisor,
      # Optional: Add max_restarts and max_seconds to prevent infinite restart loops
      max_restarts: 5,
      max_seconds: 5
    ]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        # Start periodic broadcasts after supervisor is started
        StockDashboard.Finnhub.start_periodic_broadcasts()
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start application: #{inspect(reason)}")
        # Potentially notify monitoring system here
        {:error, reason}
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    StockDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
