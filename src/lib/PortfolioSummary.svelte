<script>                                                                                    
  export let data = {                                                                       
    totalValue: 0,                                                                          
    dailyChange: 0,                                                                         
    dailyChangePercent: 0                                                                   
  };                                                                                        
                                                                                            
  // Format currency                                                                        
  const formatCurrency = (value) => {                                                       
    return new Intl.NumberFormat('en-US', {                                                 
      style: 'currency',                                                                    
      currency: 'USD'                                                                       
    }).format(value);                                                                       
  };                                                                                        
                                                                                            
  // Format percentage                                                                      
  const formatPercent = (value) => {                                                        
    return new Intl.NumberFormat('en-US', {                                                 
      style: 'percent',                                                                     
      minimumFractionDigits: 2,                                                             
      maximumFractionDigits: 2                                                              
    }).format(value / 100);                                                                 
  };                                                                                        
                                                                                            
  // Determine if change is positive or negative                                            
  $: isPositive = data.dailyChange >= 0;                                                    
</script>                                                                                   
                                                                                            
<div class="portfolio-summary">                                                             
  <div class="total-value">                                                                 
    <h3>Total Value</h3>                                                                    
    <div class="value">{formatCurrency(data.totalValue)}</div>                              
  </div>                                                                                    
                                                                                            
  <div class="daily-change">                                                                
    <h3>Today's Change</h3>                                                                 
    <div class="value-container">                                                           
      <div class="value change" class:positive={isPositive} class:negative={!isPositive}>   
        {isPositive ? '+' : ''}{formatCurrency(data.dailyChange)}                           
      </div>                                                                                
      <div class="percent change" class:positive={isPositive} class:negative={!isPositive}> 
        ({isPositive ? '+' : ''}{formatPercent(data.dailyChangePercent)})                   
      </div>                                                                                
    </div>                                                                                  
  </div>                                                                                    
</div>                                                                                      
                                                                                            
<style>                                                                                     
  .portfolio-summary {                                                                      
    display: grid;                                                                          
    grid-template-columns: 1fr;                                                             
    gap: 20px;                                                                              
    background: #f9f9f9;                                                                    
    border-radius: 8px;                                                                     
    padding: 20px;                                                                          
  }                                                                                         
                                                                                            
  h3 {                                                                                      
    font-size: 1rem;                                                                        
    color: #666;                                                                            
    margin: 0 0 8px 0;                                                                      
  }                                                                                         
                                                                                            
  .value {                                                                                  
    font-size: 1.8rem;                                                                      
    font-weight: bold;                                                                      
    color: #333;                                                                            
  }                                                                                         
                                                                                            
  .value-container {                                                                        
    display: flex;                                                                          
    align-items: baseline;                                                                  
    gap: 10px;                                                                              
  }                                                                                         
                                                                                            
  .percent {                                                                                
    font-size: 1.2rem;                                                                      
  }                                                                                         
                                                                                            
  .change.positive {                                                                        
    color: #22c55e;                                                                         
  }                                                                                         
                                                                                            
  .change.negative {                                                                        
    color: #ef4444;                                                                         
  }                                                                                         
                                                                                            
  /* Responsive layout */                                                                   
  @media (min-width: 640px) {                                                               
    .portfolio-summary {                                                                    
      grid-template-columns: repeat(2, 1fr);                                                
    }                                                                                       
  }                                                                                         
</style>                                                                                    
                