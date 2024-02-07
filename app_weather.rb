class AppWeather < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  route do |r|
    app_version = ENV["APP_VERSION"] || ENV["RACK_ENV"]
    @weather_max = (ENV["APP_WEATHER_MAX"] || APP_WEATHER_MAX_DEFAULT).to_i

    # POST /weather/add
    r.post "add" do
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

      query = ""

      struct_list = ::Service::Weather::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      weather_list = struct_list.objects
      weather_count = weather_list.length

      # render without layout
      render("weather/table", locals: {query: query, weather_count: weather_count, weather_filter: 0, weather_list: weather_list})
    end

    # POST /weather/search
    r.post "search" do
      query_raw = r.params["q"]
      query = "name:~#{query_raw}"

      struct_list = ::Service::Weather::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      weather_list = struct_list.objects
      weather_count = weather_list.length

      if query_raw != ""
        weather_filter = 1
      else
        weather_filter = 0
      end

      # render without layout
      render("weather/table", locals: {query: query, weather_count: weather_count, weather_filter: weather_filter, weather_list: weather_list})
    end

    # GET /weather/count
    r.get "count" do
      weather_count = ::Model::Weather.count()

      # render without layout
      render("weather/count")
    end

    # GET /weather
    r.get do
      app_text = "Weather"
      query = ""

      search_result = ::Service::Weather::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      weather_list = search_result.objects
      weather_count = weather_list.length

      view(
        "weather/list",
        layout: "layouts/app",
        locals: {
          app_text: app_text,
          app_version: app_version,
          query: query,
          weather_count: weather_count,
          weather_filter: 0,
          weather_list: weather_list,
        },
      )
    end

    # DELETE weather/:id
    r.delete Integer do |id|
      weather = ::Model::Weather.first(id: id)

      if weather
        weather.delete

        # set response trigger event
        response.headers["HX-Trigger"] = "weather-count-changed"
      end

      render("weather/delete")
    end

    # POST /weather/refresh
    r.post "refresh" do
      query = ""
      search_result = ::Service::Weather::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      weather_list = search_result.objects
      weather_count = weather_list.length

      # render without layout
      render("weather/table", locals: {query: query, weather_count: weather_count, weather_filter: 0, weather_list: weather_list})
    end

    # POST weather/:id
    r.post Integer do |id|
      weather = ::Model::Weather.first(id: id)

      if not weather
        response.status = 404
        return r.halt(404)
      end

      # get weather and update db

      get_result = ::Services::Weather::Api::Get.new(
        query: weather.name
      ).call

      if get_result.code == 0
        ::Service::Weather::Update.new(
          object: get_result.data
        ).call
      end

      query = ""
      struct_list = ::Service::Weather::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      weather_list = struct_list.objects
      weather_count = weather_list.length

      # render without layout
      render("weather/table", locals: {query: query, weather_count: weather_count, weather_filter: 0, weather_list: weather_list})
    end
  end
end