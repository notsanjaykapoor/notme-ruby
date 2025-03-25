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
    htmx_request = r.headers["HX-Request"] ? 1 : 0

    weather_max = (ENV["APP_WEATHER_MAX"] || APP_WEATHER_MAX_DEFAULT).to_i

    # GET /weather/add - htmx
    r.get "add" do
      if ::Model::Weather.count() >= weather_max
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
      render(
        "weather/list_table", 
        locals: {
          query: query,
          weather_count: weather_count,
          weather_filter: 0,
          weather_list: weather_list,
        }
      )
    end

    # GET /weather, /weather?q=chi - html or htmx
    r.get do
      app_text = "Weather"

      query_raw = r.params["q"].to_s
      query_normal = ::Service::Database::Query.normalize(query: query_raw, default_field: "name", default_match: "like")

      # query = ""

      search_result = ::Service::Weather::Search.new(
        query: query_normal,
        offset: 0,
        limit: 50,
      ).call

      weather_list = search_result.objects
      weather_count = weather_list.length
      weather_filter = query_raw == "" ? 0 : 1

      if htmx_request == 1
        render("weather/list_table", locals: {
          query: query_normal,
          weather_count: weather_count,
          weather_filter: weather_filter,
          weather_list: weather_list,
      })
      else
        view(
          "weather/list",
          layout: "layouts/app",
          locals: {
            app_text: app_text,
            app_version: app_version,
            query: query_normal,
            weather_count: weather_count,
            weather_filter: weather_filter,
            weather_list: weather_list,
          },
        )
      end
    end

    # DELETE weather/:id - htmx
    r.delete Integer do |id|
      weather = ::Model::Weather.first(id: id)

      if weather
        weather.delete

        # set response trigger event
        response.headers["HX-Trigger"] = "weather-count-changed"
      end

      render("weather/delete")
    end

    # POST /weather/refresh - htmx
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
      render("weather/list_table", locals: {
        query: query,
        weather_count: weather_count,
        weather_filter: 0,
        weather_list: weather_list,
      })
    end

    # PUT weather/:id - htmx
    r.put Integer do |id|
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
      render(
        "weather/list_table",
        locals: {
          query: query,
          weather_count: weather_count,
          weather_filter: 0,
          weather_list: weather_list,
        }
      )
    end
  end
end