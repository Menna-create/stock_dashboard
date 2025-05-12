defmodule StockDashboardWeb.StockChannel do
  use Phoenix.Channel
  require Logger

  # Rate limiting configuration
  @throttle_interval_ms 1000  # Minimum time between updates (1 second)

  # Join the "stock:lobby" topic
  # You can name the topic anything, but "scope:subscope" is a common convention.
  # "stock:lobby" is a general room for stock updates.
  def join("stock:lobby", _payload, socket) do
    Logger.info("Client joining stock:lobby")
    # Subscribe to the general stock trades topic
    Phoenix.PubSub.subscribe(StockDashboard.PubSub, "stock:trades")
    # You can send an initial message back to the client upon successful join
    {:ok, %{status: "connected to stock:lobby"}, socket}
  end

  # Join a specific stock symbol topic
  def join("stock:" <> symbol, _payload, socket) do
    Logger.info("Client joining stock:#{symbol}")
    
    # Subscribe to the specific symbol's PubSub topic
    Phoenix.PubSub.subscribe(StockDashboard.PubSub, "stock:#{symbol}")
    
    # Subscribe to Finnhub for this symbol if not already subscribed
    StockDashboard.Finnhub.subscribe(symbol)
    
    # Get the latest data for this symbol if available
    latest_data = case StockDashboard.Finnhub.get_latest_trade(symbol) do
      {:ok, data} -> data
      _ -> nil
    end
    
    # Store the symbol in the socket assigns
    socket = assign(socket, :symbol, symbol)
    
    # Store the last broadcast time for rate limiting
    socket = assign(socket, :last_broadcast, %{})
    
    # Return success with the latest data
    {:ok, %{status: "connected to #{symbol}", latest_data: latest_data}, socket}
  end

  # Handle "ping" events from the client
  def handle_in("ping", payload, socket) do
    Logger.info("Received ping with payload: #{inspect(payload)}")
    # Reply to the client; this will be received as a "phx_reply"
    # for the message with the "ping" event.
    {:reply, {:ok, %{response: "pong", received_message: payload["message"]}}, socket}
  end

  # Handle "subscribe" events from the client
  def handle_in("subscribe", %{"symbol" => symbol}, socket) do
    Logger.info("Client subscribing to #{symbol}")
    StockDashboard.Finnhub.subscribe(symbol)
    {:reply, {:ok, %{status: "subscribed to #{symbol}"}}, socket}
  end

  # Handle "unsubscribe" events from the client
  def handle_in("unsubscribe", %{"symbol" => symbol}, socket) do
    Logger.info("Client unsubscribing from #{symbol}")
    StockDashboard.Finnhub.unsubscribe(symbol)
    {:reply, {:ok, %{status: "unsubscribed from #{symbol}"}}, socket}
  end

  # Handle stock trades broadcasts from PubSub
  def handle_info({:stock_trades, trades}, socket) when is_list(trades) do
    # Rate limit broadcasts to prevent overwhelming the client
    if should_broadcast?(socket, "trades") do
      push(socket, "stock_update", %{trades: trades})
      socket = update_last_broadcast(socket, "trades")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # Handle stock trades for a specific symbol
  def handle_info({:stock_trades, symbol, trades}, socket) do
    # Only broadcast if this is the right symbol channel
    if socket.assigns[:symbol] == symbol do
      # Rate limit broadcasts to prevent overwhelming the client
      if should_broadcast?(socket, symbol) do
        push(socket, "stock_update", %{symbol: symbol, trades: trades})
        socket = update_last_broadcast(socket, symbol)
        {:noreply, socket}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end
  
  # Handle stock updates for a specific symbol
  def handle_info({:stock_update, symbol, data}, socket) do
    # Only broadcast if this is the right symbol channel
    if socket.assigns[:symbol] == symbol do
      # Rate limit broadcasts to prevent overwhelming the client
      if should_broadcast?(socket, "#{symbol}_update") do
        push(socket, "stock_data_update", %{
          symbol: symbol, 
          data: %{
            price: data.current_price,
            change: calculate_percentage_change(data.current_price, data.opening_price),
            volume: data.volume,
            high: data.high_price,
            low: data.low_price,
            updated_at: data.updated_at
          }
        })
        socket = update_last_broadcast(socket, "#{symbol}_update")
        {:noreply, socket}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end
  
  # Handle all stocks updates
  def handle_info({:all_stocks, stocks}, socket) do
    # Rate limit broadcasts to prevent overwhelming the client
    if should_broadcast?(socket, "all_stocks") do
      formatted_stocks = Enum.map(stocks, fn {symbol, data} -> 
        {symbol, %{
          price: data.current_price,
          change: calculate_percentage_change(data.current_price, data.opening_price),
          volume: data.volume,
          high: data.high_price,
          low: data.low_price,
          updated_at: data.updated_at
        }} 
      end) |> Enum.into(%{})
      
      push(socket, "all_stocks_update", %{stocks: formatted_stocks})
      socket = update_last_broadcast(socket, "all_stocks")
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # Private functions for rate limiting
  
  # Check if we should broadcast based on rate limiting
  defp should_broadcast?(socket, key) do
    last_time = get_in(socket.assigns.last_broadcast, [key]) || 0
    now = System.monotonic_time(:millisecond)
    now - last_time >= @throttle_interval_ms
  end
  
  # Update the last broadcast time for rate limiting
  defp update_last_broadcast(socket, key) do
    now = System.monotonic_time(:millisecond)
    last_broadcast = Map.put(socket.assigns.last_broadcast, key, now)
    assign(socket, :last_broadcast, last_broadcast)
  end
  
  # Helper function to calculate percentage change
  defp calculate_percentage_change(current, opening) when is_number(current) and is_number(opening) and opening > 0 do
    ((current - opening) / opening * 100)
    |> Float.round(2)
  end
  defp calculate_percentage_change(_, _), do: 0.0
end
