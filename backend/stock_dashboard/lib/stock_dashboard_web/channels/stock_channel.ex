defmodule StockDashboardWeb.StockChannel do                                         
     use Phoenix.Channel                                                               
     require Logger                                                                    
                                                                                       
     # Join the "stock:lobby" topic                                                    
     # You can name the topic anything, but "scope:subscope" is a common convention.   
     # "stock:lobby" is a general room for stock updates.                              
     def join("stock:lobby", _payload, socket) do                                      
       Logger.info("Client attempting to join stock:lobby")                            
       # You can send an initial message back to the client upon successful join       
       {:ok, %{status: "connected to stock:lobby"}, socket}                            
     end                                                                               
                                                                                       
     # You can add handlers for messages from the client later, e.g.:                  
     # def handle_in("ping", payload, socket) do                                       
     #   {:reply, {:ok, payload}, socket}                                              
     # end                                                                             
                                                                                       
     # You can also broadcast messages to clients on this channel                      
     # def handle_info(:some_event, socket) do                                         
     #   push(socket, "event_name", %{data: "some data"})                              
     #   {:noreply, socket}                                                            
     # end                                                                             
   end  