class AppWeather < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  route do |r|
    @weather_max = (ENV["APP_WEATHER_MAX"] || APP_WEATHER_MAX_DEFAULT).to_i

    r.post "add" do # POST /weather/add
      if ::Model::Weather.count() >= @weather_max
        response.status = 429
        return r.halt(429)
      end

      name = r.params["name"]

      # get weather

      struct_get = ::Services::Weather::Api::Get.new(
        query: name
      ).call

      if struct_get.code == 0
        # update weather data
        _update_result = ::Service::Weather::Update.new(
          object: struct_get.data
        ).call
      end

      struct_list = ::Service::Weather::Search.new(
        query: "",
        offset: 0,
        limit: 50,
      ).call

      @weather_list = struct_list.objects
      @weather_count = @weather_list.length
      @weather_filtered = 0

      # render without layout
      render("weather/table")
    end

    r.post "search" do # POST /weather/search
      query_raw = r.params["q"]
      query = "name:~#{query_raw}"

      struct_list = ::Service::Weather::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      @weather_list = struct_list.objects
      @weather_count = @weather_list.length

      if query_raw != ""
        @weather_filtered = 1
      else
        @weather_filtered = 0
      end

      # render without layout
      render("weather/table")
    end

    r.get "count" do # GET /weather/count
      @weather_count = ::Model::Weather.count()

      # render without layout
      render("weather/count")
    end

    r.get do # GET /weather
      search_result = ::Service::Weather::Search.new(
        query: "",
        offset: 0,
        limit: 50,
      ).call

      @weather_list = search_result.objects
      @weather_count = @weather_list.length
      @weather_filtered = 0
      @text = "Weather"

      view("weather/list", layout: "layouts/app")
    end

    r.delete Integer do |id| # delete weather/:id
      weather = ::Model::Weather.first(id: id)

      if weather
        weather.delete
        # set response trigger event
        response.headers["HX-Trigger"] = "weatherCountChanged"
      end

      view("weather/delete", layout: "layouts/app")
    end

    r.post "refresh" do # POST /weather/refresh
      search_result = ::Service::Weather::Search.new(
        query: "",
        offset: 0,
        limit: 50,
      ).call

      @weather_list = search_result.objects
      @weather_count = @weather_list.length
      @weather_filtered = 0

      # render without layout
      render("weather/table")
    end

    r.post Integer do |id| # POST weather/:id
      weather = ::Model::Weather.first(id: id)

      if not weather
        response.status = 404
        return r.halt(404)
      end

      # get weather

      get_result = ::Services::Weather::Api::Get.new(
        query: city.name
      ).call

      if get_result.code == 0
        # update city with weather data
        ::Service::Weather::Update.new(
          object: struct_get.data
        ).call
      end

      struct_list = ::Service::Weather::Search.new(
        query: "",
        offset: 0,
        limit: 50,
      ).call

      @weather_list = struct_list.objects
      @weather_count = @weather_list.length
      @weather_filtered = 0

      # render without layout
      render("weather/table")
    end
  end
end