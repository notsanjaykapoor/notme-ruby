# load boot file(s)

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
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)

  route do |r|
    Console.logger.info("Rack", "#{request.request_method.downcase} #{request.path}")

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

      gql_result.to_h
    end

    # GET /
    r.root do
      r.redirect "/ping"
    end

    # GET /ping
    r.get "ping" do
      env[:api_name] = "ping"

      ::Api::Ping.new(request: request, response: response).call
    end

    r.on "stocks" do
      # GET|PUT /stocks/{name}?price=x.y
      r.on String do |name|
        env[:api_name] = "stock_update"

        ::Api::Stocks::Update.new(
          request: request,
          response: response,
          name: name
        ).call
      end
    end

    # /hello branch
    r.on "hello" do
      # Set variable for all routes in /hello branch
      @greeting = 'Hello'

      # GET /hello/world request
      r.get "world" do
        "#{@greeting} world!"
      end

      # /hello request
      r.is do
        # GET /hello request
        r.get do
          "#{@greeting}!"
        end

        # POST /hello request
        r.post do
          puts "Someone said #{@greeting}!"
          r.redirect
        end
      end
    end
  end
end

run App.freeze.app
