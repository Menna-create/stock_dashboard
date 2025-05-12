defmodule StockDashboardWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :stock_dashboard
   alias CORSPlug
  

  @session_options [
    store: :cookie,
    key: "_stock_dashboard_key",
    signing_salt: "TlG+3kfW",
    same_site: "Lax"
  ]

  # Socket configuration
  socket "/socket", StockDashboardWeb.UserSocket,
    websocket: true,
    longpoll: false

  # LiveView socket
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Static files
  plug Plug.Static,
    at: "/",
    from: :stock_dashboard,
    gzip: false,
    only: StockDashboardWeb.static_paths()

  # CORS configuration (proper implementation)
  plug CORSPlug,
    origin: ["http://localhost:5173", "http://localhost:4000"],
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    headers: ["*"],
    max_age: 86400,
    credentials: true

  # Code reloading
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
