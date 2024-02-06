# boot app

require "./boot.rb"
require "./app_maps.rb"
require "./app_places.rb"
require "./app_ticker.rb"
require "./app_weather.rb"

require "rack/cors"

APP_MAPBOX_MAX_DEFAULT ||= 50
APP_TICKER_MAX_DEFAULT ||= 5
APP_WEATHER_MAX_DEFAULT ||= 2**10

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :delete, :put, :patch, :options, :head]
  end
end

class App < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  before do
    env[:start] = ::Async::Clock.now

    Thread.current[:rid] = ULID.generate()

    if request.path[/graphql/].blank?
      Console.logger.info("Rack", "#{Thread.current[:rid]} #{request.request_method.downcase} #{request.path}")
    end
  end

  after do |rack_code, rack_object|
    time_ms = ((::Async::Clock.now - env[:start])*1000).round(3)

    Console.logger.info("Rack", "#{Thread.current[:rid]} #{request.request_method.downcase} #{request.path} #{rack_code} #{time_ms}ms")
  end

  route do |r|
    @app_version = ENV["APP_VERSION"] || ENV["RACK_ENV"]
    @app_ws_uri = ENV["APP_WS_URI"]

    r.post "graphql" do
      env[:api_name] = "gql"

      gql_context = {}

      gql_params = request.params

      gql_result = GqlSchema.execute(
        gql_params["query"],
        context: gql_context,
        variables: gql_params["variables"],
        operation_name: gql_params["operationName"],
      )

      if gql_result["errors"].present?
        Console.logger.error("Rack", gql_result["errors"])
      end

      gql_result.to_h
    end

    # GET /
    r.root do
      r.redirect "/weather"
      # if request.host.include?("notme.one")
      #   r.redirect "/me"
      # else
      #   r.redirect "/weather"
      # end
    end

    r.on "ping" do # GET /ping
      env[:api_name] = "ping"

      ::Api::Ping.new(request: request, response: response).call
    end

    r.get "startup" do # GET /startup
      env[:api_name] = "startup"

      ::Api::Startup.new(request: request, response: response).call
    end

    r.get "version" do # GET /version
      env[:api_name] = "version"

      {
        "version": @app_version
      }
    end

    # api
    r.on "api/v1" do
      r.on "auth" do
        r.post "pki" do # POST /api/v1/auth/pki
          env[:api_name] = "auth_pki"

          ::Api::V1::Auth::Pki.new(request: request, response: response).call
        end
      end

      r.on "maps" do
        r.get "tileset" do # GET /api/v1/maps/tileset?lat=x&lon=y
          env[:api_name] = "tileset_get"

          ::Api::V1::Map::Tileset.new(
            request: request,
            response: response,
          ).call
        end
      end

      r.on "stocks" do
        r.on String do |ticker| # POST|PUT /api/v1/stocks/{ticker}?price=50.01
          env[:api_name] = "stock_add"

          ::Api::V1::Stocks::Update.new(
            request: request,
            response: response,
            ticker: ticker
          ).call
        end
      end

      r.on "weather" do # POST|PUT /api/v1/weather
        env[:api_name] = "weather_update"

        ::Api::V1::Weather::Update.new(
          request: request,
          response: response,
        ).call
      end
    end

    r.get "me" do # GET /me
      view("me", layout: "layouts/me")
    end

    r.on "maps" do
      r.run AppMaps
    end

    r.on "plaid" do # plaid connect
      r.get "connect" do
        struct = ::Service::Plaid::Tokens::LinkCreate.new(client_name: "notme", user_id: "sanjay").call

        @text = "Plaid Sandbox"
        @token = struct.token

        view("plaid/connect", layout: "layouts/plaid")
      end
    end

    r.on "places" do
      r.run AppPlaces
    end

    r.on "ticker" do
      r.run AppTicker
    end

    r.on "weather" do
      r.run AppWeather
    end
  end
end

run App.app
