defmodule StockDashboard.DataUtilsTest do
  use ExUnit.Case, async: true
  alias StockDashboard.DataUtils

  describe "transform_candle_data/1" do
    test "transforms valid candle data correctly" do
      # Sample Finnhub candle data
      candle_data = %{
        "s" => "ok",
        "c" => [150.0, 151.0, 149.0],
        "h" => [152.0, 153.0, 150.0],
        "l" => [148.0, 149.0, 147.0],
        "o" => [149.0, 150.0, 148.0],
        "t" => [1609459200, 1609545600, 1609632000], # 2021-01-01, 2021-01-02, 2021-01-03
        "v" => [1000, 1200, 900]
      }

      result = DataUtils.transform_candle_data(candle_data)
      
      assert result.status == :ok
      assert length(result.data) == 3
      
      [first | _] = result.data
      assert first.open == 149.0
      assert first.high == 152.0
      assert first.low == 148.0
      assert first.close == 150.0
      assert first.volume == 1000
      assert %DateTime{} = first.timestamp
    end

    test "returns error for invalid data" do
      result = DataUtils.transform_candle_data(%{"s" => "no_data"})
      assert result.status == :error
      
      result = DataUtils.transform_candle_data(nil)
      assert result.status == :error
    end
  end

  describe "transform_company_profile/1" do
    test "transforms company profile correctly" do
      profile_data = %{
        "name" => "Apple Inc",
        "ticker" => "AAPL",
        "country" => "US",
        "currency" => "USD",
        "exchange" => "NASDAQ",
        "ipo" => "1980-12-12",
        "marketCapitalization" => 2500000000,
        "shareOutstanding" => 16000000000,
        "logo" => "https://example.com/logo.png",
        "finnhubIndustry" => "Technology",
        "weburl" => "https://apple.com",
        "phone" => "1-800-275-2273"
      }

      result = DataUtils.transform_company_profile(profile_data)
      
      assert result.name == "Apple Inc"
      assert result.ticker == "AAPL"
      assert result.market_cap == "2.5B"
      assert result.shares_outstanding == "16.0B"
      assert result.industry == "Technology"
    end
  end

  describe "calculate_trends/2" do
    test "calculates trends for sufficient data points" do
      data_points = Enum.map(1..20, fn i -> 
        %{close: 100 + i, open: 99 + i, high: 101 + i, low: 98 + i}
      end)
      
      result = DataUtils.calculate_trends(data_points, %{period: 5})
      
      # The first 4 points won't have SMA
      assert length(result) == 20
      
      # Check that later points have SMA and RSI
      later_point = Enum.at(result, 10)
      assert Map.has_key?(later_point, :sma)
    end

    test "returns original data when insufficient points" do
      data_points = [
        %{close: 100, open: 99, high: 101, low: 98},
        %{close: 101, open: 100, high: 102, low: 99}
      ]
      
      result = DataUtils.calculate_trends(data_points, %{period: 5})
      assert result == data_points
    end
  end

  describe "format_large_number/1" do
    test "formats numbers with appropriate suffixes" do
      assert DataUtils.format_large_number(123) == "123.0"
      assert DataUtils.format_large_number(1234) == "1.23K"
      assert DataUtils.format_large_number(1_234_567) == "1.23M"
      assert DataUtils.format_large_number(1_234_567_890) == "1.23B"
    end

    test "handles nil and non-numeric values" do
      assert DataUtils.format_large_number(nil) == "N/A"
      assert DataUtils.format_large_number("not a number") == "N/A"
    end
  end

  describe "format_currency/2" do
    test "formats currency values correctly" do
      assert DataUtils.format_currency(1234.56) == "$1,234.56"
      assert DataUtils.format_currency(1234.56, "€") == "€1,234.56"
    end

    test "handles nil and non-numeric values" do
      assert DataUtils.format_currency(nil) == "N/A"
      assert DataUtils.format_currency("not a number") == "N/A"
    end
  end

  describe "format_percentage/2" do
    test "formats percentages correctly" do
      assert DataUtils.format_percentage(0.1234) == "12.34%"
      assert DataUtils.format_percentage(0.1234, 1) == "12.3%"
    end

    test "handles nil and non-numeric values" do
      assert DataUtils.format_percentage(nil) == "N/A"
      assert DataUtils.format_percentage("not a number") == "N/A"
    end
  end

  describe "format_date/1" do
    test "formats dates correctly" do
      datetime = DateTime.from_unix!(1609459200) # 2021-01-01
      assert DataUtils.format_date(datetime) == "2021-01-01"
    end

    test "handles invalid dates" do
      assert DataUtils.format_date(nil) == "N/A"
    end
  end
end
