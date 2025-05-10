defmodule StockDashboard.Repo do
  use Ecto.Repo,
    otp_app: :stock_dashboard,
    adapter: Ecto.Adapters.Postgres
end
