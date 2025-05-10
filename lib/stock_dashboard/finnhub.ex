defmodule StockDashboard.Finnhub do
  use GenServer
  require Logger

  @websocket_base_url "wss://ws.finnhub.io"
  # It's generally recommended to use a dedicated WebSocket client library
  # like WebSockex. For this example, we'll simulate the calls.
  # alias WebSockex # Add this if you use WebSockex

  # Finnhub expects ping messages from the client if no messages are sent for a period.
  # Or, it sends pings and expects pongs. We'll focus on auth and subscribe for now.

  # --- Public API ---

  @doc """
  Starts the Finnhub GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Authenticates the WebSocket connection using the API key.
  This is typically called automatically after connection.
  """
  def authenticate(pid \\ __MODULE__) do
    GenServer.cast(pid, :authenticate)
  end

  @doc """
  Subscribes to real-time trade updates for a given stock symbol.
  """
  def subscribe(pid \\ __MODULE__, symbol) when is_binary(symbol) do
    GenServer.cast(pid, {:subscribe, symbol})
  end

  @doc """
  Subscribes to real-time trade updates for a list of stock symbols.
  """
  def subscribe(pid \\ __MODULE__, symbols) when is_list(symbols) do
    Enum.each(symbols, &subscribe(pid, &1))
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_opts) do
    api_key = Application.fetch_env!(:stock_dashboard, :finnhub_api_key)
    state = %{
      api_key: api_key,
      ws_client: nil, # This would hold the reference to the WebSocket client process/connection
      subscriptions: MapSet.new(),
      authenticated: false
    }
    # Attempt to connect when the GenServer starts
    {:ok, state, {:continue, :connect_and_authenticate}}
  end

  @impl true
  def handle_continue(:connect_and_authenticate, state) do
    Logger.info("Attempting to connect to Finnhub WebSocket...")
    # In a real application, you would use a WebSocket client library here.
    # For example, with WebSockex:
    # ws_url = @websocket_base_url <> "?token=" <> state.api_key
    # {:ok, client} = WebSockex.start_link(ws_url, __MODULE__, %{}, name: :finnhub_ws_client)
    # The client library would then send messages like {:connected, client_ref} or
    # handle authentication via the token in the URL.
    # Finnhub also supports sending an auth message after connection if token is not in URL.

    # Simulating connection establishment and storing a placeholder client reference
    simulated_ws_client = :simulated_finnhub_ws_client
    Logger.info("Finnhub WebSocket connection established (simulated).")
    new_state = %{state | ws_client: simulated_ws_client}

    # Authenticate after connection
    send_authentication_message(new_state.ws_client, new_state.api_key)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:authenticate, state) do
    if state.ws_client && !state.authenticated do
      send_authentication_message(state.ws_client, state.api_key)
    else
      Logger.info("WebSocket not connected or already authenticated.")
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:subscribe, symbol}, state) do
    if state.ws_client && state.authenticated do
      if MapSet.member?(state.subscriptions, symbol) do
        Logger.info("Already subscribed to #{symbol}.")
        {:noreply, state}
      else
        Logger.info("Subscribing to #{symbol}...")
        # Finnhub documentation: {"type":"subscribe","symbol":"AAPL"}
        payload = %{"type" => "subscribe", "symbol" => symbol}
        send_json_message_to_websocket(state.ws_client, payload)
        new_subscriptions = MapSet.put(state.subscriptions, symbol)
        {:noreply, %{state | subscriptions: new_subscriptions}}
      end
    else
      Logger.warn("Cannot subscribe. WebSocket not connected or not authenticated.")
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:simulate_auth_success, state) do
    Logger.info("Simulated: Finnhub WebSocket authentication successful.")
    {:noreply, %{state | authenticated: true}}
  end

  # --- WebSocket Message Handling (simulated / example) ---
  # If using a library like WebSockex, you'd implement its callbacks, e.g.:
  # def handle_frame({:text, msg_json}, state) do
  #   Logger.debug("Received from Finnhub WS: #{msg_json}")
  #   case Jason.decode(msg_json) do
  #     {:ok, %{"type" => "trade", "data" => trades}} ->
  #       Logger.info("Received trades: #{inspect(trades)}")
  #       # Process trades
  #     {:ok, %{"type" => "ping"}} ->
  #       Logger.info("Received ping from Finnhub, sending pong.")
  #       send_json_message_to_websocket(state.ws_client, %{"type" => "pong"})
  #     {:ok, %{"type" => "auth_ok"}} -> # This is a hypothetical auth success message
  #        Logger.info("Finnhub WebSocket authentication successful.")
  #        {:noreply, %{state | authenticated: true}}
  #     {:ok, other_message} ->
  #       Logger.info("Received other message: #{inspect(other_message)}")
  #     {:error, reason} ->
  #       Logger.error("Failed to decode Finnhub WS message: #{inspect(reason)}")
  #   end
  #   {:noreply, state}
  # end
  #
  # def handle_info({:websockex_connected, _client}, state) do
  #   Logger.info("WebSockex connected to Finnhub. Authenticating...")
  #   send_authentication_message(state.ws_client, state.api_key) # Or ensure token is in URL
  #   {:noreply, state}
  # end
  #
  # def handle_info({:websockex_disconnected, _reason}, state) do
  #   Logger.warn("WebSockex disconnected from Finnhub. Attempting to reconnect...")
  #   # Implement reconnection logic, possibly with backoff
  #   {:noreply, %{state | ws_client: nil, authenticated: false}, {:continue, :connect_and_authenticate}}
  # end

  # --- Helper Functions ---

  defp send_authentication_message(ws_client, api_key) do
    Logger.info("Sending authentication message to Finnhub WebSocket...")
    payload = %{"type" => "auth", "token" => api_key}
    send_json_message_to_websocket(ws_client, payload)
    Logger.info("Authentication message sent.")
    # Simulate receiving an auth success message after a short delay
    Process.send_after(self(), :simulate_auth_success, 500) # Send to self
  end

  defp send_json_message_to_websocket(ws_client_ref, payload) do
    # This is a placeholder. In a real application, this would use the WebSocket
    # client library to send the JSON-encoded payload.
    # e.g., WebSockex.send_frame(ws_client_ref, {:text, Jason.encode!(payload)})
    encoded_payload = Jason.encode!(payload) # Jason should be available from your deps
    Logger.debug("Simulating send to WebSocket (#{inspect(ws_client_ref)}): #{encoded_payload}")
  end
end
