defmodule StockDashboard.StockServer do
  use GenServer
  require Logger

  alias WebSockex

  @websocket_base_url "wss://ws.finnhub.io"
  @reconnect_initial_delay_ms 1_000
  @reconnect_max_delay_ms 30_000
  @max_reconnect_attempts 10 # Set to :infinity for indefinite retries or a number

  # --- Public API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Subscribes to real-time trade updates for a given stock symbol.
  """
  def subscribe(symbol) when is_binary(symbol) do
    GenServer.cast(__MODULE__, {:subscribe, symbol})
  end

  @doc """
  Subscribes to real-time trade updates for a list of stock symbols.
  """
  def subscribe(symbols) when is_list(symbols) do
    Enum.each(symbols, &subscribe/1)
  end

  @doc """
  Unsubscribes from real-time trade updates for a given stock symbol.
  """
  def unsubscribe(symbol) when is_binary(symbol) do
    GenServer.cast(__MODULE__, {:unsubscribe, symbol})
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_opts) do
    api_key = Application.fetch_env!(:stock_dashboard, :finnhub_api_key)

    state = %{
      api_key: api_key,
      ws_client: nil,
      # For WebSockex, authentication is typically handled by including the token in the URL.
      # The 'connected' flag here means the WebSocket connection is active.
      connected: false,
      subscriptions: MapSet.new(), # Symbols we intend to be subscribed to
      active_subscriptions: MapSet.new(), # Symbols Finnhub has confirmed subscription for (optional detail)
      reconnect_attempts: 0,
      reconnect_timer: nil
    }

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    do_connect(state)
  end

  # --- WebSockex Callbacks (handled via handle_info) ---

  @impl true
  def handle_info({:websockex_connected, client_pid, _ws_state}, state) do
    Logger.info("StockServer: Successfully connected to Finnhub WebSocket.")
    new_state =
      state
      |> Map.put(:ws_client, client_pid)
      |> Map.put(:connected, true)
      |> Map.put(:reconnect_attempts, 0) # Reset on successful connection
      |> cancel_reconnect_timer()

    # Resubscribe to all intended symbols
    Enum.each(new_state.subscriptions, &send_subscribe_message(new_state.ws_client, &1))

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:websockex_disconnected, reason, _ws_state}, state) do
    Logger.warn("StockServer: Disconnected from Finnhub WebSocket. Reason: #{inspect(reason)}")
    new_state =
      state
      |> Map.put(:ws_client, nil)
      |> Map.put(:connected, false)
      |> Map.put(:active_subscriptions, MapSet.new()) # Clear active subs on disconnect

    schedule_reconnect(new_state)
  end

  @impl true
  def handle_info({:websockex_frame, {:text, msg_json}, _ws_state}, state) do
    # Logger.debug("StockServer: Received frame: #{msg_json}")
    case Jason.decode(msg_json) do
      {:ok, %{"type" => "trade", "data" => trades}} ->
        Logger.info("StockServer: Processing stock data: #{inspect(trades)}")
        # Here you would typically broadcast this data to other parts of your application
        # e.g., via Phoenix.PubSub or by sending messages to interested processes.
      {:ok, %{"type" => "ping"}} ->
        Logger.debug("StockServer: Received ping, sending pong.")
        send_pong(state.ws_client)
      {:ok, %{"type" => "subscribe", "symbol" => symbol}} -> # Hypothetical confirmation
        Logger.info("StockServer: Successfully subscribed to #{symbol} (confirmation).")
        new_state = %{state | active_subscriptions: MapSet.put(state.active_subscriptions, symbol)}
        {:noreply, new_state}
      {:ok, other_message} ->
        Logger.debug("StockServer: Received other message: #{inspect(other_message)}")
      {:error, reason} ->
        Logger.error("StockServer: Failed to decode Finnhub WS message: #{inspect(reason)}")
    end
    {:noreply, state}
  end

  @impl true
  def handle_info({:websockex_error, error, _ws_state}, state) do
    Logger.error("StockServer: WebSockex error: #{inspect(error)}")
    # Errors might not always lead to immediate disconnect, but often do.
    # If ws_client is nil, disconnect handler will schedule reconnect.
    # If connection is still perceived as up, but errors occur (e.g. send error),
    # you might want to force a reconnect or handle specific errors.
    # For simplicity, we rely on the disconnect handler for reconnections.
    {:noreply, state}
  end

  # --- Reconnection Logic ---
  @impl true
  def handle_info(:reconnect, state) do
    Logger.info("StockServer: Attempting to reconnect (attempt ##{state.reconnect_attempts + 1})...")
    new_state = %{state | reconnect_timer: nil} # Clear the timer ref
    do_connect(new_state)
  end

  # --- Internal Cast Handlers ---
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
    new_active_subscriptions = MapSet.delete(state.active_subscriptions, symbol) # also from active
    new_state = %{state | subscriptions: new_subscriptions, active_subscriptions: new_active_subscriptions}

    if state.connected && state.ws_client do
      send_unsubscribe_message(state.ws_client, symbol)
    end
    {:noreply, new_state}
  end


  # --- Helper Functions ---

  defp do_connect(state) do
    if state.ws_client do
      Logger.info("StockServer: Connection attempt skipped, client already exists.")
      return {:noreply, state}
    end

    ws_url = @websocket_base_url <> "?token=" <> state.api_key
    Logger.info("StockServer: Connecting to #{ws_url} (attempt ##{state.reconnect_attempts + 1})")

    # The third argument to WebSockex.start_link is a state that WebSockex will pass
    # back to our handle_info callbacks. We don't strictly need it here as GenServer's
    # state is already available in handle_info.
    case WebSockex.start_link(ws_url, __MODULE__, %{}, []) do
      {:ok, _client_pid} ->
        # Connection success is handled by :websockex_connected callback
        # Update reconnect_attempts here as it's per attempt cycle
        {:noreply, %{state | reconnect_attempts: state.reconnect_attempts + 1}}
      {:error, reason} ->
        Logger.error("StockServer: Failed to start WebSockex connection. Reason: #{inspect(reason)}")
        # Schedule a reconnect if WebSockex itself fails to start
        schedule_reconnect(%{state | reconnect_attempts: state.reconnect_attempts + 1})
    end
  end

  defp schedule_reconnect(state) do
    if @max_reconnect_attempts != :infinity && state.reconnect_attempts >= @max_reconnect_attempts do
      Logger.error("StockServer: Max reconnection attempts (#{@max_reconnect_attempts}) reached. Stopping.")
      # Optionally, you could stop the GenServer or notify a monitoring system.
      # For now, we just log and stop trying.
      return {:noreply, cancel_reconnect_timer(state)}
    end

    delay = calculate_backoff_delay(state.reconnect_attempts)
    Logger.info("StockServer: Scheduling reconnect in #{delay}ms.")
    timer = Process.send_after(self(), :reconnect, delay)
    {:noreply, %{state | reconnect_timer: timer}}
  end

  defp calculate_backoff_delay(attempts) do
    # Exponential backoff with some jitter
    delay = @reconnect_initial_delay_ms * (:math.pow(2, min(attempts, 6))) # Cap exponent to avoid huge delays
    jitter = :rand.uniform(round(delay * 0.2)) # Add up to 20% jitter
    min(round(delay + jitter), @reconnect_max_delay_ms)
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
      {:error, reason} -> Logger.error("StockServer: Failed to send subscribe for #{symbol}. Reason: #{inspect(reason)}")
    end
  end

  defp send_unsubscribe_message(ws_client, symbol) do
    payload = %{"type" => "unsubscribe", "symbol" => symbol}
    Logger.info("StockServer: Sending unsubscribe message for #{symbol}")
    case WebSockex.send_frame(ws_client, {:text, Jason.encode!(payload)}) do
      :ok -> :ok
      {:error, reason} -> Logger.error("StockServer: Failed to send unsubscribe for #{symbol}. Reason: #{inspect(reason)}")
    end
  end

  defp send_pong(ws_client) do
    payload = %{"type" => "pong"}
    case WebSockex.send_frame(ws_client, {:text, Jason.encode!(payload)}) do
      :ok -> :ok
      {:error, reason} -> Logger.error("StockServer: Failed to send pong. Reason: #{inspect(reason)}")
    end
  end
end
