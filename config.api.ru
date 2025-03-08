# boot app

require "./boot.rb"
require "./app_api_v1.rb"
require "./app_graph.rb"
require "./app_mapbox.rb"
require "./app_maps.rb"
require "./app_places.rb"
require "./app_ticker.rb"
require "./app_trains.rb"
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

use Rack::Static

class TraceMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["REQUEST_PATH"].to_s

    if path
      path_name = path.tr("/", "_")
    else
      path_name = "_na"
    end

    span_name = "app#{path_name}"

    AppTracer.in_span(span_name) do |span|
      @app.call(env)
    end
  end

end

class App < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :sessions, secret: ENV["APP_SECRET"]

  use ::TraceMiddleware

  before do
    env[:time_start] = ::Async::Clock.now

    Thread.current[:rid] = ULID.generate()

    if request.path[/graphql/].blank?
      Console.logger.info("Rack", "#{Thread.current[:rid]} #{request.request_method.downcase} #{request.path}")
    end
  end

  after do |rack_code, rack_object|
    env[:time_end] = ::Async::Clock.now
    time_ms = ((env[:time_end] - env[:time_start])*1000).round(3)

    Console.logger.info("Rack", "#{Thread.current[:rid]} #{request.request_method.downcase} #{request.path} #{rack_code} #{time_ms}ms")
  end

  route do |r|
    app_version = ENV["APP_VERSION"] || ENV["RACK_ENV"]

    # graphql app
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
        "version": app_version
      }
    end

    r.on "api/v1" do
      r.run AppApiV1
    end

    r.on "graph" do
      r.run AppGraph
    end

    r.on "mapbox" do
      r.run AppMapbox
    end

    r.on "maps" do
      r.run AppMaps
    end

    r.get "me" do # GET /me
      view("me", layout: "layouts/me", locals: {app_version: app_version})
    end

    # r.on "plaid" do
    #   r.run AppPlaid
    # end

    r.on "places" do
      r.run AppPlaces
    end

    r.on "ticker" do
      r.run AppTicker
    end

    r.on "trains" do
      r.run AppTrains
    end

    r.on "weather" do
      r.run AppWeather
    end
  end
end

run App.app
