defmodule StockDashboardWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :stock_dashboard

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_stock_dashboard_key",
    signing_salt: "TlG+3kfW",
    same_site: "Lax"
  ]

  # Socket for Phoenix Channels (e.g., our StockChannel)
  # This is different from the LiveView socket.
  # The path "/socket" is the default that phoenix.js client will connect to.
  socket "/socket", StockDashboardWeb.UserSocket,
    websocket: true, # You can adjust timeout
    longpoll: false # Set to true if you need longpoll fallback

  # Socket for Phoenix LiveView
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :stock_dashboard,
    gzip: false,
    only: StockDashboardWeb.static_paths()

  # Add CORSPlug before the router and before any plugs that might terminate the
  # request early
  # This is crucial for allowing your Svelte frontend (on a different port) to connect.
  plug CORSPlug

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :stock_dashboard
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug StockDashboardWeb.Router
end