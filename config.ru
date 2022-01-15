# boot app

require "./boot.rb"

require "rack/cors"

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

  before do
    env[:start] = ::Async::Clock.now
    env[:rid] = ULID.generate()

    Console.logger.info("Rack", "#{env[:rid]} #{request.request_method.downcase} #{request.path}")
  end

  after do |rack_code, rack_object|
    time_ms = ((::Async::Clock.now - env[:start])*1000).round(3)

    Console.logger.info("Rack", "#{env[:rid]} #{request.request_method.downcase} #{request.path} #{rack_code} #{time_ms}ms")
  end

  route do |r|
    r.post "graphql" do
      env[:api_name] = "gql"

      gql_context = {
        rid: env[:rid],
      }

      gql_params = request.params

      gql_result = GqlSchema.execute(
        gql_params["query"],
        context: gql_context,
        variables: gql_params["variables"],
        operation_name: gql_params["operationName"],
      )

      gql_result.to_h
    end

    # GET /
    r.root do
      r.redirect "/ping"
    end

    r.on "ping" do # GET /ping
      env[:api_name] = "ping"

      ::Api::Ping.new(request: request, response: response).call
    end

    r.get "startup" do # GET /startup
      env[:api_name] = "startup"

      ::Api::Startup.new(request: request, response: response).call
    end

    r.on "api/v1" do
      r.on "q" do
        r.on "add" do # POST|PUT /api/v1/q/add
          env[:api_name] = "q_add"

          ::Api::V1::Queue::Add.new(request: request, response: response).call
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
    end

  end
end

run App.freeze.app
