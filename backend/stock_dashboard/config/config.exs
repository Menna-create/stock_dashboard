# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Your existing config
config :stock_dashboard,
  finnhub_api_key: "d0gf7bhr01qhao4t9ptgd0gf7bhr01qhao4t9pu0",
  ecto_repos: [StockDashboard.Repo],
  generators: [timestamp_type: :utc_datetime]

# Add these new configurations that match what your modules are expecting
# For StockDashboard.Finnhub module
config :stock_dashboard, :finnhub,
  api_key: System.get_env("FINNHUB_API_KEY") || "d0gf7bhr01qhao4t9ptgd0gf7bhr01qhao4t9pu0"

# For StockDashboard.StockServer module
config :stock_dashboard, :FINNHUB_API_KEY, 
  System.get_env("FINNHUB_API_KEY") || "d0gf7bhr01qhao4t9ptgd0gf7bhr01qhao4t9pu0"

# Configures the endpoint
config :stock_dashboard, StockDashboardWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: StockDashboardWeb.ErrorHTML, json: StockDashboardWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: StockDashboard.PubSub,
  live_view: [signing_salt: "EOxlcNZ9"]

# Configures CORS for frontend connections
config :cors_plug,
  origin: ["http://localhost:5173"], # Default SvelteKit dev port
  max_age: 86400,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  headers: ["Content-Type", "Authorization"],
  credentials: true

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :stock_dashboard, StockDashboard.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"