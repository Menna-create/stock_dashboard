import Config

# Only load this in production
if config_env() == :prod do
  # Configure Finnhub API for production
  config :stock_dashboard, :finnhub,
    api_key: "d0gghcpr01qhao4thkggd0gghcpr01qhao4thkh0"

  # For StockServer
  config :stock_dashboard, :FINNHUB_API_KEY, System.fetch_env!("FINNHUB_API_KEY")
end