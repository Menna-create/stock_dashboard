{application,stock_dashboard,
    [{modules,
         ['Elixir.StockDashboard','Elixir.StockDashboard.Application',
          'Elixir.StockDashboard.DataUtils','Elixir.StockDashboard.Finnhub',
          'Elixir.StockDashboard.Finnhub.WebSocketClient',
          'Elixir.StockDashboard.Mailer','Elixir.StockDashboard.PubSub',
          'Elixir.StockDashboard.Repo','Elixir.StockDashboardWeb',
          'Elixir.StockDashboardWeb.CoreComponents',
          'Elixir.StockDashboardWeb.Endpoint',
          'Elixir.StockDashboardWeb.ErrorHTML',
          'Elixir.StockDashboardWeb.ErrorJSON',
          'Elixir.StockDashboardWeb.Gettext',
          'Elixir.StockDashboardWeb.Layouts',
          'Elixir.StockDashboardWeb.PageController',
          'Elixir.StockDashboardWeb.PageHTML',
          'Elixir.StockDashboardWeb.Router',
          'Elixir.StockDashboardWeb.StockChannel',
          'Elixir.StockDashboardWeb.Telemetry',
          'Elixir.StockDashboardWeb.UserSocket']},
     {compile_env,
         [{stock_dashboard,['Elixir.StockDashboardWeb.Gettext'],error},
          {stock_dashboard,[dev_routes],{ok,true}}]},
     {optional_applications,[]},
     {applications,
         [kernel,stdlib,elixir,logger,runtime_tools,phoenix,phoenix_ecto,
          ecto_sql,postgrex,phoenix_html,phoenix_live_reload,
          phoenix_live_view,cors_plug,corsica,phoenix_live_dashboard,swoosh,
          finch,telemetry_metrics,telemetry_poller,gettext,finnhub_api,
          phoenix_pubsub,websockex,plug_cowboy,jason,dns_cluster,bandit]},
     {description,"stock_dashboard"},
     {registered,[]},
     {vsn,"0.1.0"},
     {mod,{'Elixir.StockDashboard.Application',[]}}]}.
