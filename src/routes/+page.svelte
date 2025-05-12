<script>                                                                                    
  import PortfolioSummary from '../lib/PortfolioSummary.svelte';                            
  import StockList from '../lib/StockList.svelte';                                          
                                                                                            
  // Sample portfolio data                                                                  
  const portfolioData = {                                                                   
    totalValue: 125750.42,                                                                  
    dailyChange: 1250.30,                                                                   
    dailyChangePercent: 1.2,                                                                
    stocks: [                                                                               
      { symbol: 'AAPL', shares: 50, avgPrice: 150.25 },                                     
      { symbol: 'MSFT', shares: 30, avgPrice: 325.76 },                                     
      { symbol: 'GOOGL', shares: 15, avgPrice: 138.42 },                                    
      { symbol: 'AMZN', shares: 20, avgPrice: 132.83 },                                     
      { symbol: 'TSLA', shares: 10, avgPrice: 245.50 },                                     
      { symbol: 'META', shares: 25, avgPrice: 312.75 }                                      
    ]                                                                                       
  };                                                                                        
                                                                                            
  // Watchlist stocks (separate from portfolio)                                             
  const watchlistStocks = ['NFLX', 'DIS', 'NVDA', 'AMD'];                                   
</script>                                                                                   
                                                                                            
<main class="dashboard">                                                                    
  <header class="dashboard-header">                                                         
    <h1>Stock Dashboard</h1>                                                                
  </header>                                                                                 
                                                                                            
  <section class="portfolio-section">                                                       
    <h2>Your Portfolio</h2>                                                                 
    <PortfolioSummary data={portfolioData} />                                               
  </section>                                                                                
                                                                                            
  <section class="holdings-section">                                                        
    <h2>Holdings</h2>                                                                       
    <StockList stocks={portfolioData.stocks} type="portfolio" />                            
  </section>                                                                                
                                                                                            
  <section class="watchlist-section">                                                       
    <h2>Watchlist</h2>                                                                      
    <StockList stocks={watchlistStocks} type="watchlist" />                                 
  </section>                                                                                
</main>                                                                                     
                                                                                            
<style>                                                                                     
  .dashboard {                                                                              
    display: grid;                                                                          
    grid-template-columns: 1fr;                                                             
    gap: 20px;                                                                              
    padding: 20px;                                                                          
    max-width: 1200px;                                                                      
    margin: 0 auto;                                                                         
  }                                                                                         
                                                                                            
  .dashboard-header {                                                                       
    grid-column: 1 / -1;                                                                    
    text-align: center;                                                                     
    margin-bottom: 10px;                                                                    
  }                                                                                         
                                                                                            
  h1 {                                                                                      
    font-size: 2rem;                                                                        
    color: #333;                                                                            
    margin: 0;                                                                              
  }                                                                                         
                                                                                            
  h2 {                                                                                      
    font-size: 1.5rem;                                                                      
    color: #444;                                                                            
    margin-top: 0;                                                                          
    margin-bottom: 15px;                                                                    
    border-bottom: 1px solid #eee;                                                          
    padding-bottom: 8px;                                                                    
  }                                                                                         
                                                                                            
  section {                                                                                 
    background: white;                                                                      
    border-radius: 8px;                                                                     
    padding: 20px;                                                                          
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);                                             
  }                                                                                         
                                                                                            
  /* Responsive layout */                                                                   
  @media (min-width: 768px) {                                                               
    .dashboard {                                                                            
      grid-template-columns: repeat(2, 1fr);                                                
    }                                                                                       
                                                                                            
    .dashboard-header {                                                                     
      grid-column: 1 / -1;                                                                  
    }                                                                                       
                                                                                            
    .portfolio-section {                                                                    
      grid-column: 1 / -1;                                                                  
    }                                                                                       
  }                                                                                         
                                                                                            
  @media (min-width: 1024px) {                                                              
    .dashboard {                                                                            
      grid-template-columns: repeat(3, 1fr);                                                
    }                                                                                       
                                                                                            
    .portfolio-section {                                                                    
      grid-column: 1 / -1;                                                                  
    }                                                                                       
                                                                                            
    .holdings-section {                                                                     
      grid-column: 1 / 3;                                                                   
    }                                                                                       
                                                                                            
    .watchlist-section {                                                                    
      grid-column: 3 / 4;                                                                   
    }                                                                                       
  }                                                                                         
</style>     