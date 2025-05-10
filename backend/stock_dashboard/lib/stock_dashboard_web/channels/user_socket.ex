defmodule StockDashboardWeb.UserSocket do
  use Phoenix.Socket

  # Channels
  channel "stock:lobby", StockDashboardWeb.StockChannel

  # Socket configuration
  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil

  # Modern transport configuration (if you need custom websocket options)
  # This is now typically configured in your Endpoint instead
end