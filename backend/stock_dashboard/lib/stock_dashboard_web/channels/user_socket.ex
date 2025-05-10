defmodule StockDashboardWeb.UserSocket do                                           
     use Phoenix.Socket                                                                
                                                                                       
     # Channels                                                                        
     # Configure channels you want to expose through this socket.                      
     # Example:                                                                        
     # channel "room:*", StockDashboardWeb.RoomChannel                                 
     #                                                                                 
     # Our new channel for stock updates:                                              
     channel "stock:lobby", StockDashboardWeb.StockChannel                             
                                                                                       
     # Transports                                                                      
     # Configure transports for this socket.                                           
     # Must be listed in order of preference.                                          
     #                                                                                 
     # By default, Phoenix supports `:websocket` and `:longpoll` transports.           
     # Transports can be disabled by commenting out or removing them.                  
     #                                                                                 
     # transport :websocket, Phoenix.Transports.WebSocket                              
     # transport :longpoll, Phoenix.Transports.LongPoll                                
                                                                                       
     # Or, if you want to support both transports:                                     
     transport :websocket, Phoenix.Transports.WebSocket, timeout: 45_000               
     transport :longpoll, Phoenix.Transports.LongPoll                                  
                                                                                       
     # Identify the user connecting to the socket                                      
     #                                                                                 
     # This function will be called whenever a new socket connection is                
     # established. It should return {:ok, assigns} on success,                        
     # or :error to deny the connection.                                               
     #                                                                                 
     # For this example, we'll allow all connections.                                  
     # In a real application, you would likely authenticate the user here.             
     def connect(_params, socket, _connect_info) do                                    
       # Example:                                                                      
       # if "user_id" = get_session(socket, :user_id) do                               
       #   {:ok, assign(socket, :current_user, user_id)}                               
       # else                                                                          
       #   :error                                                                      
       # end                                                                           
       {:ok, socket}                                                                   
     end                                                                               
                                                                                       
     # This function will be called when the socket connection is closed.              
     def id(_socket), do: nil # You can return a user_id or similar if available       
   end     