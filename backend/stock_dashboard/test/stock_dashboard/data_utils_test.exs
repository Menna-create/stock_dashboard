defmodule StockDashboard.DataUtilsTest do
  use ExUnit.Case, async: true
  alias StockDashboard.DataUtils

  describe "transform_quote/1" do
    test "transforms raw quote data correctly" do
      raw_quote = %{
        "c" => 150.25,
        "pc" => 145.75,
        "h" => 152.50,
        "l" => 148.30,
        "o" => 146.80
      }

      result = DataUtils.transform_quote(raw_quote)

      assert result.price == "150.25"
      assert result.raw_price == 150.25
      assert result.change == "4.50"
      assert result.change_percent == "3.09%"
      assert result.previous_close == "145.75"
      assert result.open == "146.80"
      assert result.high == "152.50"
      assert result.low == "148.30"
      assert result.trend == :up
    end

    test "handles negative price changes" do
      raw_quote = %{
        "c" => 140.25,
        "pc" => 145.75,
        "h" => 146.50,
        "l" => 139.30,
        "o" => 145.80
      }

      result = DataUtils.transform_quote(raw_quote)

      assert result.change == "-5.50"
      assert result.trend == :down
    end
  end

  describe "transform_company_profile/1" do
    test "transforms company profile data correctly" do
      raw_profile = %{
        "name" => "Apple Inc",
        "ticker" => "AAPL",
        "exchange" => "NASDAQ",
        "finnhubIndustry" => "Technology",
        "marketCapitalization" => 2500000,
        "shareOutstanding" => 16000000,
        "logo" => "https://example.com/logo.png",
        "weburl" => "https://apple.com"
      }

      result = DataUtils.transform_company_profile(raw_profile)

      assert result.name == "Apple Inc"
      assert result.ticker == "AAPL"
      assert result.exchange == "NASDAQ"
      assert result.industry == "Technology"
      assert result.market_cap == "2.50M"
      assert result.shares_outstanding == "16.00M"
      assert result.logo == "https://example.com/logo.png"
      assert result.website == "https://apple.com"
    end
  end

  describe "transform_historical_data/1" do
    test "transforms historical data correctly" do
      raw_candles = %{
        "t" => [1625097600, 1625184000],
        "c" => [145.75, 150.25],
        "o" => [144.80, 146.75],
        "h" => [146.50, 152.00],
        "l" => [144.00, 146.50],
        "v" => [75000000, 80000000]
      }

      result = DataUtils.transform_historical_data(raw_candles)

      assert length(result) == 2
      
      [first, second] = result
      
      assert first.date == "2021-07-01"
      assert first.timestamp == 1625097600
      assert first.close == 145.75
      assert first.open == 144.80
      assert first.high == 146.50
      assert first.low == 144.00
      assert first.volume == 75000000
      
      assert second.date == "2021-07-02"
      assert second.close == 150.25
    end

    test "handles empty data" do
      result = DataUtils.transform_historical_data(%{})
      assert result == []
    end
  end

  describe "calculate_trends/1" do
    test "calculates trend statistics correctly" do
      historical_data = [
        %{close: 100.0},
        %{close: 102.0},
        %{close: 101.0},
        %{close: 103.0},
        %{close: 105.0},
        %{close: 104.0},
        %{close: 106.0}
      ]

      result = DataUtils.calculate_trends(historical_data)

      assert result.min_price == "100.00"
      assert result.max_price == "106.00"
      assert result.avg_price == "103.00"
      assert result.sma_5 == "103.80"
    end

    test "handles empty list" do
      result = DataUtils.calculate_trends([])
      assert result == %{}
    end
  end

  describe "formatting functions" do
    test "format_currency/1 formats numbers correctly" do
      assert DataUtils.format_currency(1234.567) == "1234.57"
      assert DataUtils.format_currency(0.5) == "0.50"
      assert DataUtils.format_currency(-42.123) == "-42.12"
      assert DataUtils.format_currency(nil) == "0.00"
    end

    test "format_percent/1 formats percentages correctly" do
      assert DataUtils.format_percent(12.345) == "12.35%"
      assert DataUtils.format_percent(-5.67) == "-5.67%"
      assert DataUtils.format_percent(nil) == "0.00%"
    end

    test "format_large_number/1 formats large numbers with appropriate suffixes" do
      assert DataUtils.format_large_number(1_500) == "1.50K"
      assert DataUtils.format_large_number(2_500_000) == "2.50M"
      assert DataUtils.format_large_number(3_500_000_000) == "3.50B"
      assert DataUtils.format_large_number(123) == "123.00"
      assert DataUtils.format_large_number(nil) == "0"
    end

    test "format_timestamp/1 formats Unix timestamps correctly" do
      assert DataUtils.format_timestamp(1625097600) == "2021-07-01"
      assert DataUtils.format_timestamp(nil) == ""
    end
  end

  describe "determine_trend/1" do
    test "determines trend direction correctly" do
      assert DataUtils.determine_trend(5.0) == :up
      assert DataUtils.determine_trend(-3.2) == :down
      assert DataUtils.determine_trend(0.0) == :neutral
      assert DataUtils.determine_trend(nil) == :neutral
    end
  end
end
