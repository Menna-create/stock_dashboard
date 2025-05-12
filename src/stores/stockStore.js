import { writable, derived } from 'svelte/store';                                           
                                                                                            
// Create the main store for stock data                                                     
const createStockStore = () => {                                                            
  // Initial state                                                                          
  const initialState = {                                                                    
    stocks: {},  // Map of symbol -> stock data                                             
    watchlist: [],  // Array of symbols in watchlist                                        
    portfolio: [],  // Array of portfolio items with symbol, shares, avgPrice               
    isConnected: false,  // WebSocket connection status                                     
    lastUpdated: null,  // Last data update timestamp                                       
  };                                                                                        
                                                                                            
  // Create the writable store                                                              
  const { subscribe, set, update } = writable(initialState);                                
                                                                                            
  return {                                                                                  
    subscribe,                                                                              
                                                                                            
    // Update stock data for a specific symbol                                              
    updateStock: (symbol, data) => update(state => {                                        
      const updatedStock = {                                                                
        ...state.stocks[symbol],                                                            
        ...data,                                                                            
        lastUpdated: new Date()                                                             
      };                                                                                    
                                                                                            
      return {                                                                              
        ...state,                                                                           
        stocks: { ...state.stocks, [symbol]: updatedStock },                                
        lastUpdated: new Date()                                                             
      };                                                                                    
    }),                                                                                     
                                                                                            
    // Set connection status                                                                
    setConnectionStatus: (isConnected) => update(state => ({                                
      ...state,                                                                             
      isConnected                                                                           
    })),                                                                                    
                                                                                            
    // Add a stock to watchlist                                                             
    addToWatchlist: (symbol) => update(state => {                                           
      if (!state.watchlist.includes(symbol)) {                                              
        return {                                                                            
          ...state,                                                                         
          watchlist: [...state.watchlist, symbol]                                           
        };                                                                                  
      }                                                                                     
      return state;                                                                         
    }),                                                                                     
                                                                                            
    // Remove a stock from watchlist                                                        
    removeFromWatchlist: (symbol) => update(state => ({                                     
      ...state,                                                                             
      watchlist: state.watchlist.filter(s => s !== symbol)                                  
    })),                                                                                    
                                                                                            
    // Add or update portfolio item                                                         
    updatePortfolioItem: (item) => update(state => {                                        
      const existingIndex = state.portfolio.findIndex(p => p.symbol === item.symbol);       
      let updatedPortfolio;                                                                 
                                                                                            
      if (existingIndex >= 0) {                                                             
        updatedPortfolio = [...state.portfolio];                                            
        updatedPortfolio[existingIndex] = { ...updatedPortfolio[existingIndex], ...item };  
      } else {                                                                              
        updatedPortfolio = [...state.portfolio, item];                                      
      }                                                                                     
                                                                                            
      return {                                                                              
        ...state,                                                                           
        portfolio: updatedPortfolio                                                         
      };                                                                                    
    }),                                                                                     
                                                                                            
    // Remove portfolio item                                                                
    removePortfolioItem: (symbol) => update(state => ({                                     
      ...state,                                                                             
      portfolio: state.portfolio.filter(item => item.symbol !== symbol)                     
    })),                                                                                    
                                                                                            
    // Reset store to initial state                                                         
    reset: () => set(initialState)                                                          
  };                                                                                        
};                                                                                          
                                                                                            
// Create and export the store                                                              
export const stockStore = createStockStore();                                               
                                                                                            
// Derived store for portfolio value                                                        
export const portfolioValue = derived(stockStore, $stockStore => {                          
  let total = 0;                                                                            
  let dailyChange = 0;                                                                      
                                                                                            
  $stockStore.portfolio.forEach(item => {                                                   
    const stockData = $stockStore.stocks[item.symbol];                                      
    if (stockData && stockData.price) {                                                     
      const currentValue = item.shares * stockData.price;                                   
      total += currentValue;                                                                
                                                                                            
      // Calculate daily change if we have previous close data                              
      if (stockData.previousClose) {                                                        
        const previousValue = item.shares * stockData.previousClose;                        
        dailyChange += (currentValue - previousValue);                                      
      }                                                                                     
    }                                                                                       
  });                                                                                       
                                                                                            
  const dailyChangePercent = total > 0 ? (dailyChange / (total - dailyChange)) * 100 : 0;   
                                                                                            
  return {                                                                                  
    totalValue: total,                                                                      
    dailyChange,                                                                            
    dailyChangePercent                                                                      
  };                                                                                        
});                   