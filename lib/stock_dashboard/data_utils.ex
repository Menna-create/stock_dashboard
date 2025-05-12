defmodule StockDashboard.DataUtils do
  @moduledoc """
  Utility functions for transforming stock data from Finnhub API
  to formats suitable for frontend display and analysis.
  """

  @doc """
  Transforms raw stock candle data from Finnhub to a format suitable for charts.
  
  ## Parameters
    * `candle_data` - Raw candle data from Finnhub API
    
  ## Returns
    A map with transformed data ready for frontend consumption
  """
  def transform_candle_data(candle_data) when is_map(candle_data) do
    with true <- candle_data["s"] == "ok",
         c when is_list(c) <- candle_data["c"],
         h when is_list(h) <- candle_data["h"],
         l when is_list(l) <- candle_data["l"],
         o when is_list(o) <- candle_data["o"],
         t when is_list(t) <- candle_data["t"],
         v when is_list(v) <- candle_data["v"] do
      
      data_points = Enum.zip_with([t, o, h, l, c, v], fn [timestamp, open, high, low, close, volume] ->
        %{
          timestamp: DateTime.from_unix!(timestamp),
          date: format_date(DateTime.from_unix!(timestamp)),
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume
        }
      end)
      
      %{
        status: :ok,
        data: data_points
      }
    else
      _ -> %{status: :error, message: "Invalid candle data format"}
    end
  end

  def transform_candle_data(_), do: %{status: :error, message: "Invalid candle data"}

  @doc """
  Transforms company profile data from Finnhub to a frontend-friendly format.
  
  ## Parameters
    * `profile_data` - Raw company profile from Finnhub API
    
  ## Returns
    A map with transformed profile data
  """
  def transform_company_profile(profile_data) when is_map(profile_data) do
    %{
      name: profile_data["name"],
      ticker: profile_data["ticker"],
      country: profile_data["country"],
      currency: profile_data["currency"],
      exchange: profile_data["exchange"],
      ipo: profile_data["ipo"],
      market_cap: format_large_number(profile_data["marketCapitalization"]),
      shares_outstanding: format_large_number(profile_data["shareOutstanding"]),
      logo: profile_data["logo"],
      industry: profile_data["finnhubIndustry"],
      website: profile_data["weburl"],
      phone: profile_data["phone"]
    }
  end

  def transform_company_profile(_), do: %{status: :error, message: "Invalid profile data"}

  @doc """
  Calculates historical trends from a list of data points.
  
  ## Parameters
    * `data_points` - List of data points with at least :close values
    * `options` - Calculation options (default: %{period: 14})
    
  ## Returns
    Original data with trend indicators added
  """
  def calculate_trends(data_points, options \\ %{period: 14}) when is_list(data_points) do
    period = options.period
    
    # Calculate moving averages if we have enough data
    if length(data_points) >= period do
      # Calculate simple moving average (SMA)
      data_with_sma = calculate_sma(data_points, period)
      
      # Calculate relative strength index (RSI)
      data_with_indicators = calculate_rsi(data_with_sma, period)
      
      data_with_indicators
    else
      data_points
    end
  end

  @doc """
  Formats a number for display, adding K, M, B suffixes for thousands,
  millions, and billions respectively.
  
  ## Examples
      iex> StockDashboard.DataUtils.format_large_number(1234)
      "1.23K"
      
      iex> StockDashboard.DataUtils.format_large_number(1234567)
      "1.23M"
  """
  def format_large_number(nil), do: "N/A"
  def format_large_number(number) when is_number(number) do
    cond do
      number >= 1_000_000_000 -> "#{Float.round(number / 1_000_000_000, 2)}B"
      number >= 1_000_000 -> "#{Float.round(number / 1_000_000, 2)}M"
      number >= 1_000 -> "#{Float.round(number / 1_000, 2)}K"
      true -> "#{Float.round(number, 2)}"
    end
  end
  def format_large_number(_), do: "N/A"

  @doc """
  Formats a number as currency with 2 decimal places.
  
  ## Parameters
    * `number` - The number to format
    * `currency` - Currency symbol (default: "$")
    
  ## Examples
      iex> StockDashboard.DataUtils.format_currency(1234.56)
      "$1,234.56"
  """
  def format_currency(nil, _currency \\ "$"), do: "N/A"
  def format_currency(number, currency \\ "$") when is_number(number) do
    formatted = :erlang.float_to_binary(number, [decimals: 2])
    [integer_part, decimal_part] = String.split(formatted, ".")
    
    integer_with_commas = 
      integer_part
      |> String.to_charlist()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.join(",")
      |> String.reverse()
    
    "#{currency}#{integer_with_commas}.#{decimal_part}"
  end
  def format_currency(_, _), do: "N/A"

  @doc """
  Formats a percentage value with a specified number of decimal places.
  
  ## Parameters
    * `number` - The number to format
    * `decimals` - Number of decimal places (default: 2)
    
  ## Examples
      iex> StockDashboard.DataUtils.format_percentage(0.1234)
      "12.34%"
  """
  def format_percentage(nil, _decimals \\ 2), do: "N/A"
  def format_percentage(number, decimals \\ 2) when is_number(number) do
    "#{Float.round(number * 100, decimals)}%"
  end
  def format_percentage(_, _), do: "N/A"

  @doc """
  Formats a date for display.
  
  ## Parameters
    * `datetime` - DateTime struct
    
  ## Returns
    Formatted date string (e.g., "2023-01-15")
  """
  def format_date(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d")
  end
  def format_date(_), do: "N/A"

  # Private functions

  defp calculate_sma(data_points, period) do
    data_points
    |> Enum.with_index()
    |> Enum.map(fn {point, index} ->
      if index >= period - 1 do
        window = Enum.slice(data_points, (index - period + 1)..index)
        sum = Enum.reduce(window, 0, fn p, acc -> acc + p.close end)
        sma = sum / period
        Map.put(point, :sma, sma)
      else
        point
      end
    end)
  end

  defp calculate_rsi(data_points, period) do
    # Calculate price changes
    changes = data_points
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, current] -> current.close - prev.close end)
    
    # Calculate RSI for each point after we have enough data
    data_points
    |> Enum.with_index()
    |> Enum.map(fn {point, index} ->
      if index >= period do
        window = Enum.slice(changes, (index - period)..(index - 1))
        
        gains = window |> Enum.filter(&(&1 > 0)) |> Enum.sum()
        losses = window |> Enum.filter(&(&1 < 0)) |> Enum.map(&abs/1) |> Enum.sum()
        
        avg_gain = gains / period
        avg_loss = losses / period
        
        rs = if avg_loss == 0, do: 100, else: avg_gain / avg_loss
        rsi = 100 - (100 / (1 + rs))
        
        Map.put(point, :rsi, rsi)
      else
        point
      end
    end)
  end
end
