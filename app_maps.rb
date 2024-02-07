class AppMaps < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  route do |r|
    app_version = ENV["APP_VERSION"] || ENV["RACK_ENV"]

    mapbox_max = APP_MAPBOX_MAX_DEFAULT
    mapbox_token = ENV["MAPBOX_TOKEN"]

    r.session["mapbox_session"] ||= ULID.generate()
    mapbox_session = r.session["mapbox_session"]
    mapbox_requests = (r.session["mapbox_requests"] || 0).to_i

    # GET /maps/search?city=Chicago
    r.get "search" do
      city_query = r.params["city"].to_s

      if mapbox_requests >= mapbox_max # throttle
        response.status = 429
        return render("maps/city/show_map_empty")
      end

      city_query = ::Service::Database::Query.normalize(query: city_query, default_field: "name", default_match: "like")
      resolve_result = ::Service::City::Resolve.new(query: city_query, offset: 0, limit: 5).call

      if resolve_result.code != 0
        response.status = 404
        return render("maps/city/show_map_empty")
      end

      city = resolve_result.city

      # update browser history
      response.headers["HX-Push-Url"] = "/maps?city=#{city.name}"

      r.session["mapbox_requests"] = mapbox_requests + 1

      render("maps/city/show_map", locals: {city: city, mapbox_token: mapbox_token})
    end

    # GET /maps, /maps?city=Chicago
    r.get do
      city_query = r.params["city"].to_s

      puts "mapbox session #{mapbox_session} requests #{mapbox_requests}" # xxx

      if city_query == ""
        return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
      end

      if mapbox_requests >= mapbox_max # throttle
        response.status = 429
        return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
      end

      city_query = ::Service::Database::Query.normalize(query: city_query, default_field: "name", default_match: "like")
      resolve_result = ::Service::City::Resolve.new(query: city_query, offset: 0, limit: 5).call

      if resolve_result.code != 0
        response.status = 404
        return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
      end

      city = resolve_result.city

      r.session["mapbox_requests"] = mapbox_requests + 1

      view("maps/city/show", layout: "layouts/app", locals: {city: city, mapbox_token: mapbox_token})
    end
  end
end