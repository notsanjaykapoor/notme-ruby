# boot app

require "./boot.rb"

require "rack/cors"

CITY_MAX_COUNT_DEFAULT = 2**10

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
    city_max_count = (ENV["APP_CITY_MAX_COUNT"] || CITY_MAX_COUNT_DEFAULT).to_i
    version = ENV["APP_VERSION"] || ENV["RACK_ENV"]

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
        "version": version
      }
    end

    r.on "api/v1" do
      r.on "auth" do
        r.post "pki" do # POST /api/v1/auth/pki
          env[:api_name] = "auth_pki"

          ::Api::V1::Auth::Pki.new(request: request, response: response).call
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
      @version = "dev"
      view("me")
    end

    r.on "weather" do
      r.post "add" do # post /weather/add
        if ::Model::City.count() >= city_max_count
          r.halt(422)
        end

        name = r.params["name"]

        # get weather

        struct_get = ::Services::Weather::Api::Get.new(
          query: name
        ).call

        if struct_get.code == 0
          # update city with weather data
          ::Service::City::Update.new(
            object: struct_get.data
          ).call
        end

        struct_list = ::Service::City::List.new(
          query: "",
          offset: 0,
          limit: 50,
        ).call

        @cities = struct_list.cities
        @cities_count = @cities.length
        @cities_filtered = 0

        # render without layout
        render("weather_table")
      end

      r.post "search" do # post /weather/search
        query_raw = r.params["q"]
        query = "name:~#{query_raw}"

        struct_list = ::Service::City::List.new(
          query: query,
          offset: 0,
          limit: 50,
        ).call

        @cities = struct_list.cities
        @cities_count = @cities.length

        if query_raw != ""
          @cities_filtered = 1
        else
          @cities_filtered = 0
        end

        # render without layout
        render("weather_table")
      end

      r.get "count" do # get /weather/count
        @cities_count = ::Model::City.count()

        # render without layout
        render("weather_count")
      end

      r.get do # get /weather
        struct_list = ::Service::City::List.new(
          query: "",
          offset: 0,
          limit: 50,
        ).call

        @cities = struct_list.cities
        @cities_count = @cities.length
        @cities_filtered = 0
        @text = "Weather"
        @version = version

        view("weather_list")
      end

      r.delete Integer do |id| # delete weather/:id
        city = ::Model::City.first(id: id)

        if city
          city.delete
          # set response trigger event
          response.headers["HX-Trigger"] = "weatherCountChanged"
        end

        view("weather_delete")
      end

      r.post "refresh" do # post /weather/refresh
        struct_list = ::Service::City::List.new(
          query: "",
          offset: 0,
          limit: 50,
        ).call

        @cities = struct_list.cities
        @cities_count = @cities.length
        @cities_filtered = 0

        # render without layout
        render("weather_table")
      end

      r.post Integer do |id| # post weather/:id
        city = ::Model::City.first(id: id)

        if not city
          r.halt(404)
        end

        # get weather

        struct_get = ::Services::Weather::Api::Get.new(
          query: city.name
        ).call

        if struct_get.code == 0
          # update city with weather data
          ::Service::City::Update.new(
            object: struct_get.data
          ).call
        end

        struct_list = ::Service::City::List.new(
          query: "",
          offset: 0,
          limit: 50,
        ).call

        @cities = struct_list.cities
        @cities_count = @cities.length
        @cities_filtered = 0

        # render without layout
        render("weather_table")
      end
    end
  end
end

run App.app
