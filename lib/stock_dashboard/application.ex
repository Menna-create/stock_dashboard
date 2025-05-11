defmodule StockDashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: StockDashboard.Worker.start_link(arg)
      # {StockDashboard.Worker, arg},
      #
      # Start other OTP applications and supervisors here.
      # For example, if you have a Ecto repository:
      # StockDashboard.Repo,
      #
      # If you have a Phoenix endpoint:
      # StockDashboardWeb.Endpoint,
      #
      # Add the StockServer to the supervision tree
      # StockDashboard.StockServer # Temporarily comment this out
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StockDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  # def config_change(changed, _new, removed) do
  #   StockDashboardWeb.Endpoint.config_change(changed, removed)
  #   :ok
  # end
end
