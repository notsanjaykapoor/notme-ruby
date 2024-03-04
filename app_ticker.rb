class AppTicker < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  route do |r|
    htmx_request = r.headers["HX-Request"] ? 1 : 0

    symbols_session = Set.new((r.session["symbols"] || "").split(",").map{ |s| s.strip.upcase })
    symbols_expire_session = (r.session["symbols_expire"] || Time.now.utc.to_i + (60 * 3)).to_i

    ticker_max = (ENV["APP_TICKERMAX"] || APP_TICKER_MAX_DEFAULT).to_i

    # GET /ticker/reset - html
    r.get "reset" do
      r.session.delete("symbols_expire")

      r.redirect("/ticker")
    end

    # GET /ticker - html
    r.get do
      @app_ws_uri = ENV["APP_WS_URI"]
      @symbols = (r.params["q"] || "").split(",").map{ |s| s.strip.upcase }.sort
      @stocks = {}
      @text = "Ticker"
      @expires_unix = symbols_expire_session

      if @symbols.size > ticker_max
        r.redirect "/ticker"
      end

      r.session["symbols"] = @symbols.join(",")
      r.session["symbols_expire"] = @expires_unix

      view("ticker/index", layout: "layouts/app")
    end

    # POST /ticker/add - htmx
    r.post "add" do
      add = Set.new([(r.params["q"] || "").upcase])

      if symbols_session.size < ticker_max
        # validate symbol
        code = ::Service::Stock::Verify.new(symbol: add.first).call

        if code != 0
          response.status = 404
          return r.halt(404)
        end

        symbols_session = symbols_session + add
        symbols_session = symbols_session.sort
      end

      @symbols = symbols_session

      # update session
      r.session["symbols"] = @symbols.join(",")

      # update browser history
      response.headers["HX-Push-Url"] = "/ticker?q=#{@symbols.map{ |s| s.downcase }.join(",")}"

      # trigger event
      response.headers["HX-Trigger"] = "watch-changed"

      render("ticker/symbols")
    end

    # GET /ticker/del - htmx
    r.put "del" do
      del = Set.new([(r.params["q"] || "").upcase])
      @symbols = symbols_session - del
      @symbols = @symbols.sort

      # update session
      r.session["symbols"] = @symbols.join(",")

      # update browser history
      response.headers["HX-Push-Url"] = "/ticker?q=#{@symbols.map{ |s| s.downcase }.join(",")}"

      # trigger event
      response.headers["HX-Trigger"] = "watch-changed"

      render("ticker/symbols")
    end
  end
end