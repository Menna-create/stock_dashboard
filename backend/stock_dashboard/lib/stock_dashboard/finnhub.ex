defmodule StockDashboard.Finnhub do
  @moduledoc """
  Module for handling Finnhub WebSocket connections and API interactions.
  """
  use WebSockex
  require Logger
  
  @finnhub_ws_url "wss://ws.finnhub.io?token="
  @reconnect_delay 5_000 # 5 seconds between reconnection attempts
  
  @doc """
  Starts the Finnhub WebSocket connection.
  """
  def start_link(opts \\ []) do
    # Use the exact token that worked in our test
    api_key = "d0gf7bhr01qhao4t9ptgd0gf7bhr01qhao4t9pu0"
    
    url = "#{@finnhub_ws_url}#{api_key}"
    IO.puts("Connecting to Finnhub WebSocket at #{url}")
    
    WebSockex.start_link(
      url,
      __MODULE__,  # Fixed syntax (double underscores)
      %{subscriptions: []},
      name: __MODULE__  # Fixed syntax and simplified options
    )
  end
  
  @doc """
  Subscribes to stock symbols.
  """
  def subscribe(pid \\ __MODULE__, symbol_or_symbols)  # Fixed syntax
  
  def subscribe(pid, symbols) when is_list(symbols) do
    WebSockex.cast(pid, {:subscribe, symbols})
  end
  
  def subscribe(pid, symbol) when is_binary(symbol) do
    subscribe(pid, [symbol])
  end
  
  # WebSockex callbacks
  def handle_connect(_conn, state) do
    IO.puts("✅ Connected to Finnhub WebSocket")
    # Resubscribe to any previous subscriptions
    Enum.each(state.subscriptions, &subscribe(self(), &1))
    {:ok, state}
  end
  
  def handle_disconnect(conn_status, state) do
    IO.puts("❌ Disconnected from Finnhub: #{inspect(conn_status)}")
    IO.puts("♻️ Attempting to reconnect in #{@reconnect_delay}ms...")
    Process.send_after(self(), :reconnect, @reconnect_delay)
    {:ok, state}
  end
  
  def handle_info(:reconnect, state) do
    {:reconnect, state}
  end
  
  def handle_cast({:subscribe, symbols}, state) do
    new_subscriptions = Enum.uniq(state.subscriptions ++ symbols)
    subscription_msg = %{"type" => "subscribe", "symbol" => Enum.join(symbols, ",")}
                      |> Jason.encode!()
    {:reply, {:text, subscription_msg}, %{state | subscriptions: new_subscriptions}}
  end
  
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, data} -> handle_finnhub_message(data, state)
      {:error, error} ->
        IO.puts("⚠️ Failed to decode message: #{error}\nMessage: #{msg}")
        {:ok, state}
    end
  end
  
  defp handle_finnhub_message(%{"type" => "trade", "data" => trades}, state) do
    # Process each trade
    Enum.each(trades, fn trade ->
      IO.inspect(trade, label: "📊 Trade Update")
      # Add your trade processing logic here
    end)
    {:ok, state}
  end
  
  defp handle_finnhub_message(%{"type" => "ping"}, state) do
    IO.puts("🏓 Received ping, sending pong")
    {:reply, {:text, ~s({"type":"pong"})}, state}
  end
  
  defp handle_finnhub_message(%{"type" => "error", "msg" => message}, state) do
    IO.puts("❌ Finnhub error: #{message}")
    {:ok, state}
  end
  
  defp handle_finnhub_message(msg, state) do
    IO.inspect(msg, label: "📨 Received unhandled message")
    {:ok, state}
  end
end