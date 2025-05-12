defmodule StockDashboard.PubSub do                                            
  @moduledoc """                                                              
  PubSub module for broadcasting stock data.                                  
  """                                                                         
  require Logger                                                              
                                                                              
  @doc """                                                                    
  Broadcast trade data to subscribers.                                        
  """                                                                         
  def broadcast_trades(trades) when is_list(trades) do                        
    # Group trades by symbol                                                  
    trades                                                                    
    |> Enum.group_by(& &1["s"])                                               
    |> Enum.each(fn {symbol, symbol_trades} ->                                
      # Broadcast to symbol-specific topic                                    
      Phoenix.PubSub.broadcast(                                               
        StockDashboard.PubSub,                                                
        "stock:#{symbol}",                                                    
        {:stock_trades, symbol, symbol_trades}                                
      )                                                                       
    end)                                                                      
                                                                              
    # Broadcast all trades to general topic                                   
    Phoenix.PubSub.broadcast(                                                 
      StockDashboard.PubSub,                                                  
      "stock:trades",                                                         
      {:stock_trades, trades}                                                 
    )                                                                         
                                                                              
    # Log for debugging                                                       
    Logger.debug("Broadcasted #{length(trades)} trades")                      
  end                                                                         
end                 