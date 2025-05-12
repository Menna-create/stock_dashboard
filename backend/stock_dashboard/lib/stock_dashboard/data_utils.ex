defmodule StockDashboard.DataUtils do
  @moduledoc """
  Utility functions for transforming and formatting stock data.
  
  This module provides functions to:
  - Transform raw Finnhub API data to frontend-friendly format
  - Calculate historical trends and statistics
  - Format numbers for display
  """

  alias Decimal, as: D

  @doc """
  Transforms raw stock quote data from Finnhub to a frontend-friendly format.
  
  ## Parameters
    * `quote_data` - Raw quote data from Finnhub API
    
  ## Returns
    A map with transformed and formatted data
  """
  def transform_quote(quote_data) when is_map(quote_data) do
    %{
      "c" => current_price,
      "pc" => previous_close,
      "h" => high,
      "l" => low,
      "o" => open
    } = quote_data

    # Calculate price change and percentage
    price_change = current_price - previous_close
    change_percent = (price_change / previous_close) * 100

    %{
      price: format_currency(current_price),
      raw_price: current_price,
      change: format_currency(price_change),
      change_percent: format_percent(change_percent),
      previous_close: format_currency(previous_close),
      open: format_currency(open),
      high: format_currency(high),
      low: format_currency(low),
      trend: determine_trend(price_change)
    }
  end

  @doc """
  Transforms company profile data from Finnhub to a frontend-friendly format.
  
  ## Parameters
    * `profile_data` - Raw company profile data from Finnhub API
    
  ## Returns
    A map with transformed and formatted data
  """
  def transform_company_profile(profile_data) when is_map(profile_data) do
    %{
      name: profile_data["name"],
      ticker: profile_data["ticker"],
      exchange: profile_data["exchange"],
      industry: profile_data["finnhubIndustry"],
      market_cap: format_large_number(profile_data["marketCapitalization"]),
      shares_outstanding: format_large_number(profile_data["shareOutstanding"]),
      logo: profile_data["logo"],
      website: profile_data["weburl"]
    }
  end

  @doc """
  Transforms historical stock data from Finnhub to a frontend-friendly format.
  
  ## Parameters
    * `candle_data` - Raw candle/historical data from Finnhub API
    
  ## Returns
    A list of maps with transformed data for charting
  """
  def transform_historical_data(candle_data) when is_map(candle_data) do
    timestamps = candle_data["t"] || []
    close_prices = candle_data["c"] || []
    open_prices = candle_data["o"] || []
    high_prices = candle_data["h"] || []
    low_prices = candle_data["l"] || []
    volumes = candle_data["v"] || []

    Enum.zip_with(
      [timestamps, close_prices, open_prices, high_prices, low_prices, volumes],
      fn [timestamp, close, open, high, low, volume] ->
        %{
          date: format_timestamp(timestamp),
          timestamp: timestamp,
          close: close,
          open: open,
          high: high,
          low: low,
          volume: volume
        }
      end
    )
  end

  @doc """
  Calculates trend statistics from historical data.
  
  ## Parameters
    * `historical_data` - List of historical data points
    
  ## Returns
    A map with trend statistics
  """
  def calculate_trends(historical_data) when is_list(historical_data) and length(historical_data) > 0 do
    # Extract close prices
    prices = Enum.map(historical_data, & &1.close)
    
    # Calculate simple moving averages
    sma_5 = calculate_sma(prices, 5)
    sma_20 = calculate_sma(prices, 20)
    
    # Calculate volatility (standard deviation of returns)
    returns = calculate_returns(prices)
    volatility = calculate_standard_deviation(returns)
    
    # Calculate min/max/avg
    min_price = Enum.min(prices)
    max_price = Enum.max(prices)
    avg_price = Enum.sum(prices) / length(prices)
    
    %{
      sma_5: format_currency(sma_5),
      sma_20: format_currency(sma_20),
      volatility: format_percent(volatility * 100),
      min_price: format_currency(min_price),
      max_price: format_currency(max_price),
      avg_price: format_currency(avg_price)
    }
  end
  
  def calculate_trends(_), do: %{}

  @doc """
  Formats a number as currency with 2 decimal places.
  
  ## Parameters
    * `number` - The number to format
    
  ## Returns
    Formatted string with 2 decimal places
  """
  def format_currency(number) when is_number(number) do
    number
    |> D.from_float()
    |> D.round(2)
    |> D.to_string()
  end
  
  def format_currency(nil), do: "0.00"

  @doc """
  Formats a number as a percentage with 2 decimal places.
  
  ## Parameters
    * `number` - The number to format
    
  ## Returns
    Formatted string with 2 decimal places and % sign
  """
  def format_percent(number) when is_number(number) do
    "#{format_currency(number)}%"
  end
  
  def format_percent(nil), do: "0.00%"

  @doc """
  Formats large numbers in a human-readable format (K, M, B).
  
  ## Parameters
    * `number` - The number to format
    
  ## Returns
    Formatted string with appropriate suffix
  """
  def format_large_number(number) when is_number(number) do
    cond do
      number >= 1_000_000_000 -> "#{format_currency(number / 1_000_000_000)}B"
      number >= 1_000_000 -> "#{format_currency(number / 1_000_000)}M"
      number >= 1_000 -> "#{format_currency(number / 1_000)}K"
      true -> format_currency(number)
    end
  end
  
  def format_large_number(nil), do: "0"

  @doc """
  Formats a Unix timestamp to a human-readable date string.
  
  ## Parameters
    * `timestamp` - Unix timestamp in seconds
    
  ## Returns
    Formatted date string
  """
  def format_timestamp(timestamp) when is_integer(timestamp) do
    timestamp
    |> DateTime.from_unix!()
    |> Calendar.strftime("%Y-%m-%d")
  end
  
  def format_timestamp(_), do: ""

  @doc """
  Determines the trend direction based on price change.
  
  ## Parameters
    * `price_change` - The change in price
    
  ## Returns
    :up, :down, or :neutral
  """
  def determine_trend(price_change) when is_number(price_change) do
    cond do
      price_change > 0 -> :up
      price_change < 0 -> :down
      true -> :neutral
    end
  end
  
  def determine_trend(_), do: :neutral

  # Private helper functions

  defp calculate_sma(prices, period) when length(prices) >= period do
    prices
    |> Enum.take(-period)
    |> Enum.sum()
    |> Kernel./(period)
  end
  
  defp calculate_sma(_, _), do: nil

  defp calculate_returns(prices) when length(prices) > 1 do
    prices
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, current] -> (current - prev) / prev end)
  end
  
  defp calculate_returns(_), do: []

  defp calculate_standard_deviation(values) when length(values) > 1 do
    mean = Enum.sum(values) / length(values)
    
    variance = 
      values
      |> Enum.map(fn x -> :math.pow(x - mean, 2) end)
      |> Enum.sum()
      |> Kernel./(length(values) - 1)
    
    :math.sqrt(variance)
  end
  
  defp calculate_standard_deviation(_), do: 0
end
