defmodule StockDashboard.StockServer do
  use GenServer
  require Logger

  alias WebSockex

  # Configuration for WebSocket connection and reconnection
  @websocket_base_url "wss://ws.finnhub.io"
  @reconnect_initial_delay_ms 1_000
  @reconnect_max_delay_ms 30_000
  @max_reconnect_attempts 10

  # --- Public API ---

  @doc """
  Subscribes to real-time trade updates for a given stock symbol or list of symbols.
  """
  def subscribe(symbol) when is_binary(symbol) do
    GenServer.cast(__MODULE__, {:subscribe, symbol})
  end

  def subscribe(symbols) when is_list(symbols) do
    Enum.each(symbols, &subscribe/1)
  end

  @doc """
  Unsubscribes from real-time trade updates for a given stock symbol.
  """
  def unsubscribe(symbol) when is_binary(symbol) do
    GenServer.cast(__MODULE__, {:unsubscribe, symbol})
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_opts) do
    api_key = Application.fetch_env!(:stock_dashboard, :FINNHUB_API_KEY)

    state = %{
      api_key: api_key,
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

  # --- WebSockex Callbacks ---

  @impl true
  def handle_info({:websockex_connected, client_pid, _ws_state}, state) do
    Logger.info("StockServer: Successfully connected to Finnhub WebSocket.")
    new_state =
      state
      |> Map.put(:ws_client, client_pid)
      |> Map.put(:connected, true)
      |> Map.put(:reconnect_attempts, 0)
      |> cancel_reconnect_timer()

    Enum.each(new_state.subscriptions, fn symbol ->
      send_subscribe_message(new_state.ws_client, symbol)
    end)

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:websockex_disconnected, reason, _ws_state}, state) do
    Logger.warning("StockServer: Disconnected from Finnhub WebSocket. Reason: #{inspect(reason)}")
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
        Logger.info("StockServer: Processing stock data: #{inspect(trades)}")
        {:noreply, state}
      {:ok, %{"type" => "ping"}} ->
        Logger.debug("StockServer: Received ping, sending pong.")
        send_pong(state.ws_client)
        {:noreply, state}
      {:ok, %{"type" => "subscribe", "symbol" => symbol}} ->
        Logger.info("StockServer: Successfully subscribed to #{symbol} (confirmation).")
        new_state = %{state | active_subscriptions: MapSet.put(state.active_subscriptions, symbol)}
        {:noreply, new_state}
      {:ok, other_message} ->
        Logger.debug("StockServer: Received other message: #{inspect(other_message)}")
        {:noreply, state}
      {:error, reason} ->
        Logger.error("StockServer: Failed to decode Finnhub WS message: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:websockex_error, error, _ws_state}, state) do
    Logger.error("StockServer: WebSockex error: #{inspect(error)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("StockServer: Attempting to reconnect (attempt ##{state.reconnect_attempts + 1})...")
    new_state = %{state | reconnect_timer: nil}
    do_connect(new_state)
  end

  # --- Cast Handlers ---

  @impl true
  def handle_cast({:subscribe, symbol}, state) do
    new_subscriptions = MapSet.put(state.subscriptions, symbol)
    new_state = %{state | subscriptions: new_subscriptions}

    if state.connected && state.ws_client do
      send_subscribe_message(state.ws_client, symbol)
    end
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:unsubscribe, symbol}, state) do
    new_subscriptions = MapSet.delete(state.subscriptions, symbol)
    new_active_subscriptions = MapSet.delete(state.active_subscriptions, symbol)
    new_state = %{state | 
      subscriptions: new_subscriptions, 
      active_subscriptions: new_active_subscriptions
    }

    if state.connected && state.ws_client do
      send_unsubscribe_message(state.ws_client, symbol)
    end
    {:noreply, new_state}
  end

  # --- Helper Functions ---

  defp do_connect(state) do
    if state.ws_client do
      Logger.info("""
      StockServer: Connection attempt skipped, 
      client process seems to exist or connection is in progress.
      """)
      {:noreply, state}
    else
      ws_url = @websocket_base_url <> "?token=" <> state.api_key
      Logger.info("""
      StockServer: Connecting to Finnhub WebSocket at #{ws_url} 
      (attempt ##{state.reconnect_attempts + 1})
      """)

      case WebSockex.start_link(ws_url, __MODULE__, %{}, []) do
        {:ok, _client_pid} ->
          {:noreply, %{state | reconnect_attempts: state.reconnect_attempts + 1}}
        {:error, reason} ->
          Logger.error("""
          StockServer: Failed to start WebSockex connection. 
          Reason: #{inspect(reason)}
          """)
          schedule_reconnect(%{state | reconnect_attempts: state.reconnect_attempts + 1})
      end
    end
  end

  defp schedule_reconnect(state) do
    if @max_reconnect_attempts != :infinity && state.reconnect_attempts >= @max_reconnect_attempts do
      Logger.error("""
      StockServer: Max reconnection attempts (#{@max_reconnect_attempts}) reached.
      Stopping reconnection efforts.
      """)
      {:noreply, cancel_reconnect_timer(state)}
    else
      delay = calculate_backoff_delay(state.reconnect_attempts)
      Logger.info("StockServer: Scheduling reconnect in #{delay}ms.")
      timer = Process.send_after(self(), :reconnect, delay)
      {:noreply, %{state | reconnect_timer: timer}}
    end
  end

  defp calculate_backoff_delay(attempts) do
    base_delay = @reconnect_initial_delay_ms * :math.pow(2, min(attempts, 6))
    jitter = :rand.uniform(round(base_delay * 0.2))
    min(round(base_delay + jitter), @reconnect_max_delay_ms)
  end

  defp cancel_reconnect_timer(state) do
    if timer_ref = state.reconnect_timer do
      Process.cancel_timer(timer_ref)
    end
    %{state | reconnect_timer: nil}
  end

  defp send_subscribe_message(ws_client, symbol) do
    payload = %{"type" => "subscribe", "symbol" => symbol}
    Logger.info("StockServer: Sending subscribe message for #{symbol}")
    case WebSockex.send_frame(ws_client, {:text, Jason.encode!(payload)}) do
      :ok -> :ok
      {:error, reason} -> 
        Logger.error("StockServer: Failed to send subscribe for #{symbol}. Reason: #{inspect(reason)}")
    end
  end

  defp send_unsubscribe_message(ws_client, symbol) do
    payload = %{"type" => "unsubscribe", "symbol" => symbol}
    Logger.info("StockServer: Sending unsubscribe message for #{symbol}")
    case WebSockex.send_frame(ws_client, {:text, Jason.encode!(payload)}) do
      :ok -> :ok
      {:error, reason} -> 
        Logger.error("StockServer: Failed to send unsubscribe for #{symbol}. Reason: #{inspect(reason)}")
    end
  end

  defp send_pong(ws_client) do
    payload = %{"type" => "pong"}
    case WebSockex.send_frame(ws_client, {:text, Jason.encode!(payload)}) do
      :ok -> :ok
      {:error, reason} -> 
        Logger.error("StockServer: Failed to send pong. Reason: #{inspect(reason)}")
    end
  end
end