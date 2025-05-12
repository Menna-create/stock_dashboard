defmodule StockDashboard.Scripts.TestFinnhub do               
  def run do                                                  
    IO.puts("Testing Finnhub ETS storage...")                 
                                                              
    # Subscribe to some stocks                                
    symbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "META"]       
    Enum.each(symbols, &StockDashboard.Finnhub.subscribe/1)   
                                                              
    IO.puts("Subscribed to #{Enum.join(symbols, ", ")}")      
    IO.puts("Waiting for data to come in...")                 
                                                              
    # Wait for some data to come in                           
    Process.sleep(10_000)                                     
                                                              
    # Check what we've got                                    
    stocks = StockDashboard.Finnhub.get_all_stocks()          
    IO.puts("Got data for #{map_size(stocks)} stocks")        
                                                              
    # Print details for each stock                            
    Enum.each(stocks, fn {symbol, data} ->                    
      IO.puts("\n#{symbol}:")                                 
      IO.puts("  Current price: #{data.current_price}")       
      IO.puts("  Opening price: #{data.opening_price}")       
      IO.puts("  High: #{data.high_price}")                   
      IO.puts("  Low: #{data.low_price}")                     
      IO.puts("  Volume: #{data.volume}")                     
      IO.puts("  Updated at: #{data.updated_at}")             
                                                              
      # Get percentage change                                 
      {:ok, change} =                                         
StockDashboard.Finnhub.get_percentage_change(symbol)          
      IO.puts("  Change: #{change}%")                         
    end)                                                      
                                                              
    # Get frontend data                                       
    frontend_data = StockDashboard.Finnhub.get_frontend_data()
    IO.puts("\nFrontend data sample:")                        
    IO.inspect(Enum.take(frontend_data, 2), pretty: true)     
  end                                                         
end    