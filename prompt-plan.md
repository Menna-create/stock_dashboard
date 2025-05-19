# Step-by-Step Aider Prompts for Stock Dashboard Project

Structured sequence of prompts to implement the project from an empty folder.

## Milestone 1: Project Setup

### Step 1: Initialize Monorepo Structure

Let's create a monorepo structure for our Phoenix backend and Svelte frontend. Please:
1. Create a new directory called `stock_dashboard`
2. Inside it, create two directories: `backend` and `frontend`
3. Initialize a git repository in the root folder
4. Create a basic README.md explaining the project structure

### Step 2: Set Up Phoenix Backend

Now let's set up the Phoenix backend. Please:
1. Change to the backend directory
2. Create a new Phoenix project called `stock_dashboard` with the --no-assets flag
3. Add the required dependencies to mix.exs:
   - `{:finnhub, "~> 0.1"}` for Finnhub API
   - `{:jason, "~> 1.2"}` for JSON handling
   - `{:phoenix_pubsub, "~> 2.0"}` for PubSub
4. Create a basic .gitignore file for Elixir projects

### Step 3: Create Svelte Frontend

Now let's set up the Svelte frontend. Please:
1. Change to the frontend directory
2. Initialize a new Svelte project using the official template
3. Install required dependencies:
   - phoenix.js for channel connection
   - chart.js for stock charts
   - svelte-chartjs for Chart.js integration
4. Create a basic .gitignore file for Svelte projects

### Step 4: Establish Basic Connectivity

Let's establish basic connectivity between frontend and backend. Please:
1. In the Phoenix backend, create a basic channel at `lib/stock_dashboard_web/channels/stock_channel.ex`
2. Set up the channel to accept connections and reply with a simple "connected" message
3. In the Svelte frontend, modify src/App.svelte to:
   - Connect to the Phoenix socket
   - Join the stock channel
   - Log the connection status
4. Add basic CORS configuration to the Phoenix endpoint

## Milestone 2: API Integration

### Step 1: Implement Finnhub API Authentication

Let's implement Finnhub API authentication. Please:
1. Create a new module at `lib/stock_dashboard/finnhub.ex`
2. Implement functions to:
   - Start the Finnhub WebSocket connection
   - Authenticate with the API key
   - Subscribe to stock symbols
3. Add configuration for the API key in config/config.exs

### Step 2: Create GenServers for WebSocket Management

Now let's create GenServers for WebSocket management. Please:
1. Create a GenServer at `lib/stock_dashboard/stock_server.ex` to:
   - Manage the Finnhub WebSocket connection
   - Handle reconnection logic
   - Process incoming stock data
2. Create a supervisor at `lib/stock_dashboard/application.ex` to supervise this GenServer
3. Implement basic error handling for connection failures

### Step 3: Test Basic Data Retrieval

Let's test basic data retrieval. Please:
1. Create a test file at `test/stock_dashboard/stock_server_test.exs`
2. Implement a test case that:
   - Starts the StockServer
   - Subscribes to a test symbol
   - Verifies data can be received
3. Add mock responses for testing

### Step 4: Implement ETS Storage for Stock Data

Now implement ETS storage for stock data. Please:
1. Modify the StockServer to:
   - Create an ETS table on startup
   - Store incoming stock data in the table
   - Provide functions to query the table
2. Add functions to calculate percentage changes
3. Implement basic data transformation for frontend consumption

## Milestone 3: Data Flow

### Step 1: Set Up Phoenix Channels for Data Broadcasting

Let's set up Phoenix Channels for data broadcasting. Please:
1. Enhance the existing StockChannel at `lib/stock_dashboard_web/channels/stock_channel.ex` to:
   - Accept subscriptions for specific symbols
   - Broadcast updates when new data arrives
2. Modify the StockServer to publish updates via PubSub
3. Implement rate limiting to prevent excessive updates

### Step 2: Create Data Transformation Utilities

Now create data transformation utilities. Please:
1. Create a module at `lib/stock_dashboard/data_utils.ex` with functions to:
   - Transform raw Finnhub data to frontend format
   - Calculate historical trends
   - Format numbers for display
2. Add tests for these transformations

### Step 3: Begin Basic Frontend Components

Let's start basic frontend components. Please:
1. Create a Svelte component at `src/lib/StockCard.svelte` that:
   - Connects to the stock channel
   - Displays a single stock's current price
   - Shows up/down indicator
2. Modify App.svelte to use this component

## Milestone 4: Frontend Development

### Step 1: Build Dashboard UI Components

Let's build the dashboard UI components. Please:
1. Create a responsive layout in `src/App.svelte` using CSS Grid
2. Create components for:
   - Portfolio summary (`src/lib/PortfolioSummary.svelte`)
   - Stock list (`src/lib/StockList.svelte`)
   - Individual stock cards (`src/lib/StockCard.svelte`)
3. Implement responsive design for mobile and desktop

### Step 2: Implement Real-time Data Display

Now implement real-time data display. Please:
1. Enhance StockCard.svelte to:
   - Show percentage change with color coding
   - Display last updated time
   - Add loading states
2. Create a store at `src/stores/stockStore.js` to manage application state

### Step 3: Create Stock Charts and Indicators

Let's add stock charts. Please:
1. Create a component at `src/lib/StockChart.svelte` that:
   - Uses Chart.js to display price history
   - Shows 30-minute trend line
   - Updates in real-time
2. Style the chart to match the dashboard theme
3. Add error handling for missing data

## Milestone 5: Testing and Refinement

### Step 1: Add Backend Tests

Let's add backend tests. Please:
1. Expand the test suite to cover:
   - Channel communication
   - Data transformations
   - Error handling
2. Add property-based tests for critical components
3. Implement CI configuration

### Step 2: Add Frontend Tests

Now add frontend tests. Please:
1. Set up Jest for Svelte testing
2. Create tests for:
   - StockCard component
   - StockChart rendering
   - Store updates
3. Add accessibility tests

### Step 3: Implement Error Handling and Recovery

Let's implement error handling. Please:
1. Add error boundaries to frontend components
2. Implement reconnection logic in the Phoenix channel
3. Add visual feedback for connection issues
4. Implement retry logic for failed API calls

## Milestone 6: Documentation and Submission

### Step 1: Complete Project Documentation

Let's document the project. Please:
1. Write comprehensive README.md covering:
   - Project structure
   - Setup instructions
   - Key features
2. Add inline documentation for complex functions
3. Create API documentation for the backend

### Step 2: Prepare Final Submission

Now prepare final submission. Please:
1. Verify all requirements are met
2. Run final tests
3. Create a production build
4. Generate a zip file of the complete project