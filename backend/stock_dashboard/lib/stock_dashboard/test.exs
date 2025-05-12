# test_finnhub.exs
Mix.install([
  {:websockex, "~> 0.4.3"},
  {:jason, "~> 1.2"}
])

defmodule FinnhubTest do
  use WebSockex
  require Logger

  def start_link do
    # Use the exact token that worked in your manual test
    token = "d0gghcpr01qhao4thkggd0gghcpr01qhao4thkh0"
    url = "wss://ws.finnhub.io?token=#{token}"
    
    IO.puts("Connecting to: #{url}")
    WebSockex.start_link(url, __MODULE__, %{})
  end

  def handle_connect(_conn, state) do
    IO.puts("Connected successfully!")
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    IO.puts("Received: #{msg}")
    {:ok, state}
  end

  def handle_disconnect(%{reason: reason}, state) do
    IO.puts("Disconnected: #{inspect(reason)}")
    {:reconnect, state}
  end
end

{:ok, pid} = FinnhubTest.start_link()
# Keep the script running
Process.sleep(:infinity)