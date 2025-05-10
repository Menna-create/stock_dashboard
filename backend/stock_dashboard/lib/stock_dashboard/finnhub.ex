defmodule StockDashboard.Finnhub do
  @moduledoc """
  Module for handling Finnhub WebSocket connections and API interactions.
  """

  use WebSockex

  @finnhub_ws_url "wss://ws.finnhub.io?token="
  @reconnect_delay 5_000 # 5 seconds between reconnection attempts

  @doc """
  Starts the Finnhub WebSocket connection.
  """
  def start_link(opts \\ []) do
    api_key = Keyword.get(opts, :api_key) || Application.get_env(:stock_dashboard, :finnhub)[:api_key]
    
    if is_nil(api_key) do
      raise "Finnhub API key not configured. Set config :stock_dashboard, :finnhub, api_key: \"your_key\""
    end

    WebSockex.start_link(
      "#{@finnhub_ws_url}#{api_key}",
      __MODULE__,
      %{subscriptions: []},
      Keyword.merge(opts, name: __MODULE__)
    )
  end

  @doc """
  Subscribes to stock symbols.
  """
   def subscribe(pid \\ __MODULE__, symbol_or_symbols)

  # Then implement the clauses
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