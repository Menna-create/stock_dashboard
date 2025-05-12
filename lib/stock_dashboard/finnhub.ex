defmodule StockDashboard.Finnhub do
  @moduledoc """
  Combined implementation of Finnhub GenServer and WebSockex client.
  Handles WebSocket connections, subscriptions, and reconnection logic.
  Stores stock data in ETS tables for efficient access.
  """
  use GenServer
  require Logger

  # WebSocket configuration
  @finnhub_ws_url "wss://ws.finnhub.io"
  @reconnect_initial_delay_ms 1_000
  @reconnect_max_delay_ms 30_000
  @max_reconnect_attempts 10
  @api_key "d0gghcpr01qhao4thkggd0gghcpr01qhao4thkh0"

  # ETS table names
  @trades_table :finnhub_trades
  @stock_data_table :finnhub_stock_data

  # Client API
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def subscribe(symbol) when is_binary(symbol), do: GenServer.cast(__MODULE__, {:subscribe, symbol})
  def subscribe(symbols) when is_list(symbols), do: Enum.each(symbols, &subscribe/1)
  def unsubscribe(symbol) when is_binary(symbol), do: GenServer.cast(__MODULE__, {:unsubscribe, symbol})

  # ETS data access functions
  @doc """
  Get the latest trade data for a specific symbol.
  """
  def get_latest_trade(symbol) do
    case :ets.lookup(@stock_data_table, symbol) do
      [{^symbol, data}] -> {:ok, data}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Get all available stock data.
  """
  def get_all_stocks do
    @stock_data_table
    |> :ets.tab2list()
    |> Enum.map(fn {symbol, data} -> {symbol, data} end)
    |> Enum.into(%{})
  end

  @doc """
  Get the percentage change for a specific symbol.
  """
  def get_percentage_change(symbol) do
    case get_latest_trade(symbol) do
      {:ok, %{current_price: current, opening_price: opening}} when not is_nil(current) and not is_nil(opening) and opening > 0 ->
        {:ok, calculate_percentage_change(current, opening)}
      {:ok, _} ->
        {:error, :invalid_data}
      error ->
        error
    end
  end

  @doc """
  Get formatted stock data for frontend consumption.
  """
  def get_frontend_data do
    get_all_stocks()
    |> Enum.map(fn {symbol, data} ->
      %{
        symbol: symbol,
        price: data.current_price,
        change: calculate_percentage_change(data.current_price, data.opening_price),
        volume: data.volume,
        high: data.high_price,
        low: data.low_price,
        updated_at: data.updated_at
      }
    end)
  end

  # GenServer callbacks
  @impl true
  def init(_opts) do
    # Create ETS tables
    :ets.new(@trades_table, [:named_table, :ordered_set, :public, read_concurrency: true])
    :ets.new(@stock_data_table, [:named_table, :set, :public, read_concurrency: true])

    state = %{
      ws_client: nil,
      connected: false,
      subscriptions: MapSet.new(),
      active_subscriptions: MapSet.new(),
      reconnect_attempts: 0,
      reconnect_timer: nil
    }

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    do_connect(state)
  end

  # WebSocket connection handling
  @impl true
  def handle_info({:websockex_connected, client_pid, _ws_state}, state) do
    Logger.info("✅ Connected to Finnhub WebSocket")
    new_state =
      state
      |> Map.put(:ws_client, client_pid)
      |> Map.put(:connected, true)
      |> Map.put(:reconnect_attempts, 0)
      |> cancel_reconnect_timer()

    Enum.each(new_state.subscriptions, &send_subscribe_message(new_state.ws_client, &1))
    {:noreply, new_state}
  end

  @impl true
  def handle_info({:websockex_disconnected, reason, _ws_state}, state) do
    Logger.error("❌ Disconnected from Finnhub: #{inspect(reason)}")
    new_state =
      state
      |> Map.put(:ws_client, nil)
      |> Map.put(:connected, false)
      |> Map.put(:active_subscriptions, MapSet.new())

    schedule_reconnect(new_state)
  end

  @impl true
  def handle_info({:websockex_frame, {:text, msg_json}, _ws_state}, state) do
    case Jason.decode(msg_json) do
      {:ok, %{"type" => "trade", "data" => trades}} ->
        handle_trade_data(trades)
        {:noreply, state}

      {:ok, %{"type" => "ping"}} ->
        send_pong(state.ws_client)
        {:noreply, state}

      {:ok, %{"type" => "subscribe", "symbol" => symbol}} ->
        Logger.info("Subscribed to #{symbol}")
        new_state = %{state | active_subscriptions: MapSet.put(state.active_subscriptions, symbol)}
        {:noreply, new_state}

      {:ok, other} ->
        Logger.debug("Received: #{inspect(other)}")
        {:noreply, state}

      {:error, reason} ->
        Logger.error("Failed to decode message: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("♻️ Attempting reconnect (attempt #{state.reconnect_attempts + 1})")
    new_state = %{state | reconnect_timer: nil}
    do_connect(new_state)
  end

  # Subscription management
  @impl true
  def handle_cast({:subscribe, symbol}, state) do
    new_state = %{state | subscriptions: MapSet.put(state.subscriptions, symbol)}
    if state.connected, do: send_subscribe_message(state.ws_client, symbol)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:unsubscribe, symbol}, state) do
    new_state = %{state | 
      subscriptions: MapSet.delete(state.subscriptions, symbol),
      active_subscriptions: MapSet.delete(state.active_subscriptions, symbol)
    }
    if state.connected, do: send_unsubscribe_message(state.ws_client, symbol)
    {:noreply, new_state}
  end

  # Private functions
  defp do_connect(state) do
    if state.ws_client do
      {:noreply, state}
    else
      ws_url = "#{@finnhub_ws_url}?token=#{@api_key}"
      Logger.info("Connecting to #{String.replace(ws_url, ~r/token=(.{5})(.*)(.{5})/, "token=\\1...\\3")}")

      case StockDashboard.Finnhub.WebSocketClient.start_link(ws_url, self()) do
        {:ok, pid} ->
          {:noreply, %{state | ws_client: pid, reconnect_attempts: state.reconnect_attempts + 1}}
          
        {:error, reason} ->
          Logger.error("Failed to start WebSockex connection. \nReason: #{inspect(reason)}")
          schedule_reconnect(%{state | reconnect_attempts: state.reconnect_attempts + 1})
      end
    end
  end

  defp schedule_reconnect(state) do
    if @max_reconnect_attempts != :infinity && state.reconnect_attempts >= @max_reconnect_attempts do
      Logger.error("Max reconnect attempts reached")
      {:noreply, cancel_reconnect_timer(state)}
    else
      delay = calculate_backoff_delay(state.reconnect_attempts)
      Logger.info("Reconnecting in #{delay}ms")
      timer = Process.send_after(self(), :reconnect, delay)
      {:noreply, %{state | reconnect_timer: timer}}
    end
  end

  defp calculate_backoff_delay(attempts) do
    base = @reconnect_initial_delay_ms * :math.pow(2, min(attempts, 6)) |> round()
    jitter = :rand.uniform(round(base * 0.2))
    min(base + jitter, @reconnect_max_delay_ms)
  end

  defp cancel_reconnect_timer(state) do
    if timer_ref = state.reconnect_timer, do: Process.cancel_timer(timer_ref)
    %{state | reconnect_timer: nil}
  end

  defp send_subscribe_message(ws_client, symbol) do
    payload = %{"type" => "subscribe", "symbol" => symbol}
    WebSockex.send_frame(ws_client, {:text, Jason.encode!(payload)})
  rescue
    error ->
      Logger.error("Failed to send subscribe message: #{inspect(error)}")
      {:error, error}
  end

  defp send_unsubscribe_message(ws_client, symbol) do
    payload = %{"type" => "unsubscribe", "symbol" => symbol}
    WebSockex.send_frame(ws_client, {:text, Jason.encode!(payload)})
  rescue
    error ->
      Logger.error("Failed to send unsubscribe message: #{inspect(error)}")
      {:error, error}
  end

  defp send_pong(ws_client) do
    WebSockex.send_frame(ws_client, {:text, Jason.encode!(%{"type" => "pong"})})
  rescue
    error ->
      Logger.error("Failed to send pong message: #{inspect(error)}")
      {:error, error}
  end

  defp handle_trade_data(trades) do
    # Store trades in ETS
    Enum.each(trades, &store_trade/1)
    
    # Update aggregated stock data
    Enum.group_by(trades, & &1["s"])
    |> Enum.each(&update_stock_data/1)
    
    # Broadcast to Phoenix channels or process trades
    StockDashboard.PubSub.broadcast_trades(trades)
  end

  defp store_trade(trade) do
    trade_id = "#{trade["s"]}_#{trade["t"]}"
    :ets.insert(@trades_table, {trade_id, trade})
  end

  defp update_stock_data({symbol, trades}) do
    # Get the current data or initialize a new one
    current_data = case :ets.lookup(@stock_data_table, symbol) do
      [{^symbol, data}] -> data
      [] -> init_stock_data()
    end
    
    # Process the new trades
    new_data = Enum.reduce(trades, current_data, fn trade, acc ->
      price = trade["p"]
      volume = trade["v"]
      
      %{
        current_price: price,
        opening_price: acc.opening_price || price,
        high_price: max(acc.high_price || price, price),
        low_price: min(acc.low_price || price, price),
        volume: acc.volume + volume,
        trade_count: acc.trade_count + 1,
        updated_at: DateTime.utc_now()
      }
    end)
    
    # Store the updated data
    :ets.insert(@stock_data_table, {symbol, new_data})
    
    # Broadcast the updated stock data
    StockDashboard.PubSub.broadcast_stock_update(symbol, new_data)
    
    # Return the new data
    new_data
  end

  defp init_stock_data do
    %{
      current_price: nil,
      opening_price: nil,
      high_price: nil,
      low_price: nil,
      volume: 0,
      trade_count: 0,
      updated_at: DateTime.utc_now()
    }
  end

  defp calculate_percentage_change(current, opening) when is_number(current) and is_number(opening) and opening > 0 do
    ((current - opening) / opening * 100)
    |> Float.round(2)
  end
  defp calculate_percentage_change(_, _), do: 0.0
end

defmodule StockDashboard.Finnhub.WebSocketClient do
  @moduledoc """
  WebSockex client implementation for Finnhub WebSocket connection.
  """
  use WebSockex
  require Logger

  def start_link(url, parent_pid) do
    try do
      WebSockex.start_link(url, __MODULE__, %{parent: parent_pid}, 
        async: true,
        handle_initial_conn_failure: true,
        extra_headers: [{"User-Agent", "StockDashboard"}]
      )
    rescue
      error -> 
        Logger.error("WebSockex start_link error: #{inspect(error)}")
        {:error, error}
    catch
      kind, reason ->
        Logger.error("WebSockex start_link caught #{kind}: #{inspect(reason)}")
        {:error, {kind, reason}}
    end
  end

  @impl true
  def handle_connect(_conn, %{parent: parent} = state) do
    send(parent, {:websockex_connected, self(), nil})
    {:ok, state}
  end

  @impl true
  def handle_disconnect(%{reason: reason} = conn_state, %{parent: parent} = state) do
    send(parent, {:websockex_disconnected, reason, conn_state})
    {:ok, state}
  end

  @impl true
  def handle_frame(frame, %{parent: parent} = state) do
    send(parent, {:websockex_frame, frame, state})
    {:ok, state}
  end

  @impl true
  def handle_ping(_ping, state) do 
    {:reply, :pong, state}
  end

  @impl true
  def terminate(reason, %{parent: parent}) do
    Logger.error("WebSocket terminating: #{inspect(reason)}")
    send(parent, {:websockex_disconnected, reason, nil})
    :ok
  end
end
