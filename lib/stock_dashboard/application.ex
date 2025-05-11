defmodule StockDashboard.Application do
  @moduledoc false
  use Application
  require Logger  # Added Logger requirement
  
  @impl true
  def start(_type, _args) do
    # Start the Finnhub client with the working token directly
    # Comment out the conditional logic that was causing issues
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
      
      # Start Finnhub WebSocket connection with hardcoded working token
      # For testing, use only one of the Finnhub clients
      {StockDashboard.Finnhub, []},  # No need to pass the token, it's hardcoded now
      
      # Comment out StockServer temporarily for testing
      # StockDashboard.StockServer,
      
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