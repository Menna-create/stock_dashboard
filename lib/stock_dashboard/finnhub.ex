defmodule StockDashboard.Finnhub do
  @moduledoc """
  Module for handling Finnhub WebSocket connections and API interactions.
  """
  use WebSockex
  require Logger  # Added this
  
  @finnhub_ws_url "wss://ws.finnhub.io?token="
  @reconnect_delay 5_000 # 5 seconds between reconnection attempts
  
  @doc """
  Starts the Finnhub WebSocket connection.
  """
  def start_link(opts \\ []) do
    api_key = get_api_key(opts)
    url = "#{@finnhub_ws_url}#{api_key}"
    
    # Add debug logging
    Logger.info("Connecting to Finnhub WebSocket at #{String.replace(url, ~r/token=(.{5})(.*)(.{5})/, "token=\\1...\\3")}")
    
    WebSockex.start_link(
      url,
      __MODULE__,  # Fixed syntax
      %{subscriptions: []},
      name: name(opts)
    )
  end
  
  defp get_api_key(_opts) do
    # Direct fix - hardcode the working key
    "d0gf7bhr01qhao4t9ptgd0gf7bhr01qhao4t9pu0"
  end
  
  defp name(opts), do: Keyword.get(opts, :name, __MODULE__)  # Fixed syntax
  
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
    Logger.info("Connected to Finnhub WebSocket")
    {:ok, state}
  end
  
  def handle_disconnect(conn_status, state) do
    Logger.warn("Disconnected from Finnhub: #{inspect(conn_status)}")  # Fixed function name
    Logger.info("Attempting to reconnect in #{@reconnect_delay}ms...")
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
        Logger.error("Failed to decode message: #{error}\nMessage: #{msg}")
        {:ok, state}
    end
  end
  
  defp handle_finnhub_message(%{"type" => "trade", "data" => trades}, state) do
    Enum.each(trades, fn trade ->
      Logger.debug("Trade Update: #{inspect(trade)}")
      # Broadcast to Phoenix.PubSub or process trades
    end)
    {:ok, state}
  end
  
  defp handle_finnhub_message(%{"type" => "ping"}, state) do
    Logger.debug("Received ping, sending pong")
    {:reply, {:text, ~s({"type":"pong"})}, state}
  end
  
  defp handle_finnhub_message(%{"type" => "error", "msg" => message}, state) do
    Logger.error("Finnhub error: #{message}")
    {:ok, state}
  end
  
  defp handle_finnhub_message(msg, state) do
    Logger.debug("Received unhandled message: #{inspect(msg)}")
    {:ok, state}
  end
end