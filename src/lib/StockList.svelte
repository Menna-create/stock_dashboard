<script>
  import StockCard from './StockCard.svelte';
  
  // Props
  export let stocks = [];
  export let type = 'watchlist'; // 'watchlist' or 'portfolio'
  
  // Format for display
  const formatShares = (shares) => {
    return shares.toLocaleString('en-US');
  };
  
  const formatCurrency = (value) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(value);
  };
</script>

<div class="stock-list {type}">
  {#if type === 'portfolio' && stocks.length > 0}
    <div class="list-header">
      <div class="col symbol">Symbol</div>
      <div class="col shares">Shares</div>
      <div class="col avg-price">Avg Price</div>
      <div class="col current">Current</div>
      <div class="col value">Value</div>
    </div>
  {/if}
  
  <div class="list-body">
    {#if stocks.length === 0}
      <div class="empty-state">
        {type === 'portfolio' ? 'No stocks in your portfolio yet.' : 'Your watchlist is empty.'}
      </div>
    {:else}
      {#each stocks as stock}
        {#if type === 'portfolio'}
          <div class="stock-row">
            <div class="col symbol">{stock.symbol}</div>
            <div class="col shares">{formatShares(stock.shares)}</div>
            <div class="col avg-price">{formatCurrency(stock.avgPrice)}</div>
            <div class="col current">
              <StockCard symbol={stock.symbol} compact={true} />
            </div>
            <div class="col value">
              {#if stock.currentPrice}
                {formatCurrency(stock.shares * stock.currentPrice)}
              {:else}
                --
              {/if}
            </div>
          </div>
        {:else}
          <div class="stock-card-container">
            <StockCard symbol={stock} />
          </div>
        {/if}
      {/each}
    {/if}
  </div>
</div>

<style>
  .stock-list {
    width: 100%;
  }
  
  .list-header {
    display: none;
    font-weight: bold;
    color: #666;
    border-bottom: 1px solid #eee;
    padding-bottom: 8px;
    margin-bottom: 8px;
  }
  
  .stock-row {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
    padding: 12px 0;
    border-bottom: 1px solid #f0f0f0;
  }
  
  .stock-row .col {
    display: flex;
    align-items: center;
  }
  
  .stock-row .symbol {
    font-weight: bold;
  }
  
  .stock-card-container {
    margin-bottom: 16px;
  }
  
  .empty-state {
    text-align: center;
    color: #888;
    padding: 20px;
    font-style: italic;
  }
  
  /* Responsive layout */
  @media (min-width: 640px) {
    .list-header {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr 1fr 1fr;
    }
    
    .stock-row {
      grid-template-columns: 1fr 1fr 1fr 1fr 1fr;
    }
  }
  
  @media (max-width: 639px) {
    .stock-row {
      position: relative;
    }
    
    .stock-row .col {
      position: relative;
    }
    
    .stock-row .col::before {
      content: attr(class);
      text-transform: capitalize;
      font-size: 0.75rem;
      color: #888;
      display: block;
      margin-bottom: 2px;
    }
    
    .stock-row .col.symbol::before {
      display: none;
    }
  }
</style>