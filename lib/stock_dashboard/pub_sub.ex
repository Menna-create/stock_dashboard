defmodule StockDashboard.PubSub do
  @moduledoc """
  Handles PubSub broadcasts for stock data.
  """
  
  @doc """
  Broadcast trades to all subscribers of the general trades topic.
  """
  def broadcast_trades(trades) when is_list(trades) do
    Phoenix.PubSub.broadcast(
      StockDashboard.PubSub,
      "stock:trades",
      {:stock_trades, trades}
    )
    
    # Also broadcast to individual symbol topics
    trades
    |> Enum.group_by(& &1["s"])
    |> Enum.each(fn {symbol, symbol_trades} ->
      broadcast_symbol_trades(symbol, symbol_trades)
    end)
  end
  
  @doc """
  Broadcast trades for a specific symbol.
  """
  def broadcast_symbol_trades(symbol, trades) when is_binary(symbol) and is_list(trades) do
    Phoenix.PubSub.broadcast(
      StockDashboard.PubSub,
      "stock:#{symbol}",
      {:stock_trades, symbol, trades}
    )
  end
  
  @doc """
  Broadcast stock data updates.
  """
  def broadcast_stock_update(symbol, data) when is_binary(symbol) do
    Phoenix.PubSub.broadcast(
      StockDashboard.PubSub,
      "stock:#{symbol}",
      {:stock_update, symbol, data}
    )
  end
  
  @doc """
  Broadcast all stock data.
  """
  def broadcast_all_stocks(stocks) when is_map(stocks) do
    Phoenix.PubSub.broadcast(
      StockDashboard.PubSub,
      "stock:lobby",
      {:all_stocks, stocks}
    )
  end
end
