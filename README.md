Project Description                                        

Stock Dashboard is a comprehensive web application designed
for real-time monitoring and analysis of stock market data.
This platform provides users with customizable dashboards  
to track stock performance, visualize market trends, and   
make informed investment decisions.                        

The application is built as a monorepo containing both     
backend and frontend components:                           

 • The backend is powered by Elixir with the Phoenix       
   framework, providing robust, real-time data processing  
 • The frontend is built with Svelte, offering a responsive
   and interactive user interface                          


Screenshots                                                

🌆 Dashboard Overview  Main dashboard showing multiple stoc
real-time data                                             

🌆 Stock Detail View  Detailed view of a single stock with 
performance charts                                         

🌆 Customization Panel  User interface for customizing dash
tracked stocks                                             


Architecture                                               

Backend (Elixir/Phoenix)                                   

 • Data Layer: PostgreSQL database accessed via Ecto ORM   
 • API Layer: RESTful endpoints and GraphQL API for data   
   access                                                  
 • Real-time Updates: Phoenix Channels for WebSocket       
   communication                                           
 • Authentication: JWT-based authentication system         

Frontend (Svelte)                                          

 • State Management: Svelte stores for application state   
 • UI Components: Modular, reusable components             
 • Data Visualization: Interactive charts using D3.js or   
   Chart.js                                                
 • Responsive Design: Mobile-first approach for all device 
   sizes                                                   

System Architecture                                        

                                                           
┌─────────────────┐      ┌─────────────────┐               
┌─────────────────┐                                        
│                 │      │                 │      │        
│                                                          
│  Svelte Frontend│◄────►│  Phoenix Backend│◄────►│        
PostgreSQL DB  │                                           
│                 │      │                 │      │        
│                                                          
└─────────────────┘      └─────────────────┘               
└─────────────────┘                                        
        ▲                        ▲                         
        │                        │                         
        ▼                        ▼                         
┌─────────────────┐      ┌─────────────────┐               
│                 │      │                 │               
│  Browser Client │      │  Stock Data APIs│               
│                 │      │                 │               
└─────────────────┘      └─────────────────┘               
                                                           


Setup Instructions                                         

Prerequisites                                              

 • Elixir 1.13+                                            
 • Erlang 24+                                              
 • PostgreSQL 13+                                          
 • Node.js 16+                                             
 • npm 8+                                                  

Backend Setup                                              

 1 Navigate to the backend directory:                      
                                                           
   cd backend/stock_dashboard                              
                                                           
 2 Install dependencies:                                   
                                                           
   mix deps.get                                            
                                                           
 3 Set up the database:                                    
                                                           
   mix ecto.setup                                          
                                                           
 4 Start the Phoenix server:                               
                                                           
   mix phx.server                                          
                                                           
   The backend will be available at http://localhost:4000  

Frontend Setup                                             

 1 Navigate to the frontend directory:                     
                                                           
   cd frontend                                             
                                                           
 2 Install dependencies:                                   
                                                           
   npm install                                             
                                                           
 3 Start the development server:                           
                                                           
   npm run dev                                             
                                                           
   The frontend will be available at http://localhost:3000 

Environment Configuration                                  

 1 Copy the example environment files:                     
                                                           
   cp backend/stock_dashboard/config/dev.exs.example       
   backend/stock_dashboard/config/dev.exs                  
   cp frontend/.env.example frontend/.env                  
                                                           
 2 Update the configuration files with your database       
   credentials and API keys                                


Development                                                

Running Tests                                              

 • Backend: cd backend/stock_dashboard && mix test         
 • Frontend: cd frontend && npm run test                   

Code Formatting                                            

 • Backend: cd backend/stock_dashboard && mix format       
 • Frontend: cd frontend && npm run lint 
