import Config

# Only load this in production
if config_env() == :prod do
  # Configure Finnhub API for production
  config :stock_dashboard, :finnhub,
    api_key: "d0gf7bhr01qhao4t9ptgd0gf7bhr01qhao4t9pu0"

  # For StockServer
  config :stock_dashboard, :FINNHUB_API_KEY, System.fetch_env!("FINNHUB_API_KEY")
end