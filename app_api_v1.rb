class AppApiV1 < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :sessions, secret: ENV["APP_SECRET"]

  route do |r|
    r.on "auth" do
      # POST /api/v1/auth/pki
      r.post "pki" do
        env[:api_name] = "auth_pki"

        ::Api::V1::Auth::Pki.new(request: request, response: response).call
      end
    end

    r.on "maps" do
      # GET /api/v1/maps/tileset?lat=x&lon=y
      r.get "tileset" do
        env[:api_name] = "tileset_get"

        ::Api::V1::Map::Tileset.new(
          request: request,
          response: response,
        ).call
      end
    end

    r.on "stocks" do
      # POST|PUT /api/v1/stocks/{ticker}?price=50.01
      r.on String do |ticker|
        env[:api_name] = "stock_add"

        ::Api::V1::Stocks::Update.new(
          request: request,
          response: response,
          ticker: ticker
        ).call
      end
    end

    # POST|PUT /api/v1/weather
    r.on "weather" do
      env[:api_name] = "weather_update"

      ::Api::V1::Weather::Update.new(
        request: request,
        response: response,
      ).call
    end
  end
end