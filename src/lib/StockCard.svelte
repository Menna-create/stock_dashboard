<script>                                                                                    
  import { onMount, onDestroy } from 'svelte';                                              
  import { Socket } from 'phoenix';                                                         
  import { stockStore } from '../stores/stockStore.js';                                     
  import { formatCurrency, formatPercent, formatTime } from '../utils/formatters.js';       
                                                                                            
  // Props                                                                                  
  export let symbol = '';                                                                   
  export let initialPrice = null;                                                           
  export let compact = false; // For compact display                                        
                                                                                            
  // State                                                                                  
  let price = initialPrice;                                                                 
  let previousPrice = initialPrice;                                                         
  let previousClose = null;                                                                 
  let percentChange = null;                                                                 
  let priceDirection = null; // 'up', 'down', or null                                       
  let lastUpdated = null;                                                                   
  let socket;                                                                               
  let channel;                                                                              
  let connected = false;                                                                    
  let loading = true;                                                                       
  let error = null;                                                                         
                                                                                            
  // Format the last updated time                                                           
  $: formattedTime = lastUpdated ? formatTime(lastUpdated) : '';                            
                                                                                            
  onMount(() => {                                                                           
    loading = true;                                                                         
                                                                                            
    // Connect to Phoenix socket                                                            
    socket = new Socket('ws://localhost:4000/socket', {params: {token: window.userToken}}); 
    console.log(`Connecting to socket for ${symbol}...`);                                   
    socket.connect();                                                                       
                                                                                            
    // Join the stock channel for this specific symbol                                      
    channel = socket.channel(`stock:${symbol}`, {});                                        
                                                                                            
    channel.join()                                                                          
      .receive('ok', resp => {                                                              
        console.log(`Joined stock channel for ${symbol}`, resp);                            
        connected = true;                                                                   
        error = null;                                                                       
                                                                                            
        if (resp.latest_data) {                                                             
          const data = resp.latest_data;                                                    
          if (data.current_price) {                                                         
            updatePrice(data.current_price);                                                
          }                                                                                 
          if (data.previous_close) {                                                        
            previousClose = data.previous_close;                                            
            updatePercentChange();                                                          
          }                                                                                 
        }                                                                                   
                                                                                            
        loading = false;                                                                    
      })                                                                                    
      .receive('error', resp => {                                                           
        console.error(`Unable to join stock channel for ${symbol}`, resp);                  
        error = `Failed to connect: ${resp.reason || 'Unknown error'}`;                     
        loading = false;                                                                    
      });                                                                                   
                                                                                            
    // Listen for price updates                                                             
    channel.on('stock_data_update', payload => {                                            
      console.log(`Received update for ${symbol}:`, payload);                               
      if (payload.data) {                                                                   
        if (payload.data.price) {                                                           
          updatePrice(payload.data.price);                                                  
        }                                                                                   
        if (payload.data.previous_close) {                                                  
          previousClose = payload.data.previous_close;                                      
          updatePercentChange();                                                            
        }                                                                                   
                                                                                            
        // Update the store with all available data                                         
        stockStore.updateStock(symbol, {                                                    
          price: payload.data.price,                                                        
          previousClose: payload.data.previous_close,                                       
          high: payload.data.high,                                                          
          low: payload.data.low,                                                            
          volume: payload.data.volume,                                                      
          percentChange: percentChange                                                      
        });                                                                                 
      }                                                                                     
    });                                                                                     
                                                                                            
    // Add debugging for socket connection                                                  
    socket.onOpen(() => {                                                                   
      console.log(`Socket opened for ${symbol}`);                                           
      stockStore.setConnectionStatus(true);                                                 
    });                                                                                     
                                                                                            
    socket.onError((err) => {                                                               
      console.error(`Socket error for ${symbol}:`, err);                                    
      error = "Connection error";                                                           
      stockStore.setConnectionStatus(false);                                                
    });                                                                                     
                                                                                            
    socket.onClose(() => {                                                                  
      console.log(`Socket closed for ${symbol}`);                                           
      stockStore.setConnectionStatus(false);                                                
    });                                                                                     
  });                                                                                       
                                                                                            
  onDestroy(() => {                                                                         
    if (channel) {                                                                          
      channel.leave();                                                                      
    }                                                                                       
    if (socket) {                                                                           
      socket.disconnect();                                                                  
    }                                                                                       
  });                                                                                       
                                                                                            
  function updatePrice(newPrice) {                                                          
    if (price !== null) {                                                                   
      previousPrice = price;                                                                
      priceDirection = newPrice > previousPrice ? 'up' : newPrice < previousPrice ? 'down' :
priceDirection;                                                                             
    }                                                                                       
    price = newPrice;                                                                       
    lastUpdated = new Date();                                                               
    updatePercentChange();                                                                  
  }                                                                                         
                                                                                            
  function updatePercentChange() {                                                          
    if (price !== null && previousClose !== null && previousClose > 0) {                    
      percentChange = ((price - previousClose) / previousClose) * 100;                      
    }                                                                                       
  }                                                                                         
                                                                                            
  // For testing - simulate price updates                                                   
  function simulateUpdate() {                                                               
    const change = (Math.random() - 0.5) * 5;                                               
    const newPrice = price ? price + change : 100 + change;                                 
    updatePrice(Math.max(0.01, newPrice));                                                  
                                                                                            
    // Simulate previous close if not set                                                   
    if (previousClose === null) {                                                           
      previousClose = newPrice * (1 - (Math.random() * 0.05));                              
      updatePercentChange();                                                                
    }                                                                                       
  }                                                                                         
</script>                                                                                   
                                                                                            
{#if compact}                                                                               
  <!-- Compact version for use in tables -->                                                
  <div class="stock-price-compact" class:up={priceDirection === 'up'}                       
class:down={priceDirection === 'down'}>                                                     
    {#if loading}                                                                           
      <div class="loading-indicator">                                                       
        <div class="spinner"></div>                                                         
      </div>                                                                                
    {:else if error}                                                                        
      <div class="error-indicator">!</div>                                                  
    {:else if price !== null}                                                               
      <div class="price-container">                                                         
        <span class="price">${price.toFixed(2)}</span>                                      
        {#if priceDirection === 'up'}                                                       
          <span class="direction-indicator">↑</span>                                        
        {:else if priceDirection === 'down'}                                                
          <span class="direction-indicator">↓</span>                                        
        {/if}                                                                               
      </div>                                                                                
                                                                                            
      {#if percentChange !== null}                                                          
        <div class="percent-change" class:positive={percentChange >= 0}                     
class:negative={percentChange < 0}>                                                         
          {percentChange >= 0 ? '+' : ''}{percentChange.toFixed(2)}%                        
        </div>                                                                              
      {/if}                                                                                 
    {:else}                                                                                 
      <span class="no-data">--</span>                                                       
    {/if}                                                                                   
  </div>                                                                                    
{:else}                                                                                     
  <!-- Full card version -->                                                                
  <div class="stock-card" class:loading={loading} class:error={error}>                      
    <div class="stock-header">                                                              
      <div class="stock-symbol">{symbol}</div>                                              
      {#if lastUpdated}                                                                     
        <div class="last-updated">Updated: {formattedTime}</div>                            
      {/if}                                                                                 
    </div>                                                                                  
                                                                                            
    {#if loading}                                                                           
      <div class="loading-state">                                                           
        <div class="spinner"></div>                                                         
        <div class="loading-text">Loading...</div>                                          
      </div>                                                                                
    {:else if error}                                                                        
      <div class="error-message">{error}</div>                                              
    {:else if price !== null}                                                               
      <div class="stock-price" class:up={priceDirection === 'up'} class:down={priceDirection
=== 'down'}>                                                                                
        ${price.toFixed(2)}                                                                 
                                                                                            
        {#if priceDirection === 'up'}                                                       
          <span class="direction-indicator">↑</span>                                        
        {:else if priceDirection === 'down'}                                                
          <span class="direction-indicator">↓</span>                                        
        {/if}                                                                               
      </div>                                                                                
                                                                                            
      {#if percentChange !== null}                                                          
        <div class="percent-change" class:positive={percentChange >= 0}                     
class:negative={percentChange < 0}>                                                         
          {percentChange >= 0 ? '+' : ''}{percentChange.toFixed(2)}%                        
        </div>                                                                              
      {/if}                                                                                 
    {:else}                                                                                 
      <div class="stock-price no-data">No data available</div>                              
    {/if}                                                                                   
                                                                                            
    <!-- For testing only - remove in production -->                                        
    <button class="test-button" on:click={simulateUpdate}>                                  
      Simulate Update                                                                       
    </button>                                                                               
  </div>                                                                                    
{/if}                                                                                       
                                                                                            
<style>                                                                                     
  .stock-card {                                                                             
    background: white;                                                                      
    border-radius: 8px;                                                                     
    padding: 16px;                                                                          
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);                                               
    transition: all 0.3s ease;                                                              
  }                                                                                         
                                                                                            
  .stock-card.loading {                                                                     
    opacity: 0.7;                                                                           
  }                                                                                         
                                                                                            
  .stock-card.error {                                                                       
    border-left: 3px solid #ef4444;                                                         
  }                                                                                         
                                                                                            
  .stock-header {                                                                           
    display: flex;                                                                          
    justify-content: space-between;                                                         
    align-items: center;                                                                    
    margin-bottom: 12px;                                                                    
  }                                                                                         
                                                                                            
  .stock-symbol {                                                                           
    font-weight: bold;                                                                      
    font-size: 1.2rem;                                                                      
    color: #333;                                                                            
  }                                                                                         
                                                                                            
  .last-updated {                                                                           
    font-size: 0.7rem;                                                                      
    color: #888;                                                                            
  }                                                                                         
                                                                                            
  .stock-price {                                                                            
    font-size: 1.8rem;                                                                      
    font-weight: bold;                                                                      
    margin-bottom: 8px;                                                                     
    display: flex;                                                                          
    align-items: center;                                                                    
    gap: 8px;                                                                               
  }                                                                                         
                                                                                            
  .stock-price.up {                                                                         
    color: #22c55e;                                                                         
  }                                                                                         
                                                                                            
  .stock-price.down {                                                                       
    color: #ef4444;                                                                         
  }                                                                                         
                                                                                            
  .direction-indicator {                                                                    
    font-size: 1.2rem;                                                                      
  }                                                                                         
                                                                                            
  .percent-change {                                                                         
    font-size: 1rem;                                                                        
    font-weight: 500;                                                                       
    margin-bottom: 12px;                                                                    
  }                                                                                         
                                                                                            
  .percent-change.positive {                                                                
    color: #22c55e;                                                                         
  }                                                                                         
                                                                                            
  .percent-change.negative {                                                                
    color: #ef4444;                                                                         
  }                                                                                         
                                                                                            
  .loading-state {                                                                          
    display: flex;                                                                          
    flex-direction: column;                                                                 
    align-items: center;                                                                    
    justify-content: center;                                                                
    padding: 20px 0;                                                                        
  }                                                                                         
                                                                                            
  .spinner {                                                                                
    width: 24px;                                                                            
    height: 24px;                                                                           
    border: 3px solid rgba(0, 0, 0, 0.1);                                                   
    border-radius: 50%;                                                                     
    border-top-color: #3b82f6;                                                              
    animation: spin 1s ease-in-out infinite;                                                
    margin-bottom: 8px;                                                                     
  }                                                                                         
                                                                                            
  @keyframes spin {                                                                         
    to { transform: rotate(360deg); }                                                       
  }                                                                                         
                                                                                            
  .loading-text {                                                                           
    color: #888;                                                                            
    font-size: 0.9rem;                                                                      
  }                                                                                         
                                                                                            
  .error-message {                                                                          
    color: #ef4444;                                                                         
    padding: 12px 0;                                                                        
    font-size: 0.9rem;                                                                      
  }                                                                                         
                                                                                            
  .no-data {                                                                                
    color: #888;                                                                            
    font-style: italic;                                                                     
  }                                                                                         
                                                                                            
  .test-button {                                                                            
    margin-top: 12px;                                                                       
    padding: 6px 12px;                                                                      
    background: #f0f0f0;                                                                    
    border: none;                                                                           
    border-radius: 4px;                                                                     
    cursor: pointer;                                                                        
    font-size: 0.8rem;                                                                      
    transition: background 0.2s;                                                            
  }                                                                                         
                                                                                            
  .test-button:hover {                                                                      
    background: #e0e0e0;                                                                    
  }                                                                                         
                                                                                            
  /* Compact version styles */                                                              
  .stock-price-compact {                                                                    
    display: flex;                                                                          
    flex-direction: column;                                                                 
    font-size: 1rem;                                                                        
  }                                                                                         
                                                                                            
  .stock-price-compact .price-container {                                                   
    display: flex;                                                                          
    align-items: center;                                                                    
    gap: 4px;                                                                               
  }                                                                                         
                                                                                            
  .stock-price-compact.up .price {                                                          
    color: #22c55e;                                                                         
  }                                                                                         
                                                                                            
  .stock-price-compact.down .price {                                                        
    color: #ef4444;                                                                         
  }                                                                                         
                                                                                            
  .stock-price-compact .percent-change {                                                    
    font-size: 0.8rem;                                                                      
  }                                                                                         
                                                                                            
  .loading-indicator {                                                                      
    display: flex;                                                                          
    justify-content: center;                                                                
  }                                                                                         
                                                                                            
  .loading-indicator .spinner {                                                             
    width: 16px;                                                                            
    height: 16px;                                                                           
    border-width: 2px;                                                                      
  }                                                                                         
                                                                                            
  .error-indicator {                                                                        
    color: #ef4;
  } 
</style>