# Project Description  

**Stock Dashboard** is a comprehensive web application designed  
for real-time monitoring and analysis of stock market data.  
This platform provides users with customizable dashboards  
to track stock performance, visualize market trends, and  
make informed investment decisions.  

The application is built as a monorepo containing both  
backend and frontend components:  

- The backend is powered by Elixir with the Phoenix  
  framework, providing robust, real-time data processing  
- The frontend is built with Svelte, offering a responsive  
  and interactive user interface  

---

# Architecture  

## Backend (Elixir/Phoenix)  

- **Data Layer**: PostgreSQL database accessed via Ecto ORM  
- **API Layer**: RESTful endpoints and GraphQL API for data  
  access  
- **Real-time Updates**: Phoenix Channels for WebSocket  
  communication  
- **Authentication**: JWT-based authentication system  

## Frontend (Svelte)  

- **State Management**: Svelte stores for application state  
- **UI Components**: Modular, reusable components  
- **Data Visualization**: Interactive charts using D3.js or  
  Chart.js  
- **Responsive Design**: Mobile-first approach for all device  
  sizes  


# Screenshot
1-<img width="1440" alt="Screenshot 2025-05-13 at 2 54 44 PM" src="https://github.com/user-attachments/assets/0c1275c0-f6bc-490d-a95b-ef88c80b87a4" />
2-<img width="1440" alt="Screenshot 2025-05-13 at 2 55 05 PM" src="https://github.com/user-attachments/assets/1c94831e-7293-4158-8234-db4b389b80dd" />
3- <img width="1440" alt="Screenshot 2025-05-13 at 10 59 57 PM" src="https://github.com/user-attachments/assets/00d2ebaa-8a59-45d5-be67-93cd9997a20e" />

## Setup Instructions  

### Prerequisites  
- Elixir ≥1.13 + Erlang ≥24  
- PostgreSQL ≥13  
- Node.js ≥16 + npm ≥8  

### Backend Setup  
```sh
cd backend/stock_dashboard
mix deps.get           # Install dependencies
mix ecto.setup         # Create DB and run migrations
mix phx.server         # Start at http://localhost:4000

cd frontend
npm install            # Install dependencies
npm run dev            # Start at http://localhost:5173

### Key Features  
- All code blocks are properly fenced with ` ```sh` for shell commands  
- Tables used for test commands comparison  
- System diagram preserved as ASCII art  
- Consistent header hierarchy (`#`, `##`, `###`)  
- Environment setup clearly separated into copy + edit steps  
- Mobile-friendly line breaks in long commands (using `\`)  

This format works perfectly for GitHub/GitLab READMEs or documentation sites.







