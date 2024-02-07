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
    htmx_request = r.headers["HX-Request"] ? 1 : 0

    mapbox_max = (ENV["APP_MAPBOX_MAX"] || APP_MAPBOX_MAX_DEFAULT).to_i
    mapbox_token = ENV["MAPBOX_TOKEN"]

    r.session["mapbox_session"] ||= ULID.generate()
    mapbox_session = r.session["mapbox_session"]
    mapbox_requests = (r.session["mapbox_requests"] || 0).to_i

    # GET /maps/city/:id, html
    r.get "city", Integer do |city_id|
      city = ::Model::City.first(id: city_id)

      if not city
        response.status = 422
        return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
      end

      Console.logger.info(self, "city #{city.name} mapbox session #{mapbox_session} requests #{mapbox_requests}/#{mapbox_max}")

      if mapbox_requests >= mapbox_max # throttle
        response.status = 429
        return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
      end

      r.session["mapbox_requests"] = mapbox_requests + 1

      view("maps/city/show", layout: "layouts/app", locals: {city: city, mapbox_token: mapbox_token})
    end

    # GET /maps, optional city=name param, html or htmx
    r.get do
      city_query = r.params["city"].to_s

      Console.logger.info(self, "query '#{city_query}' mapbox session #{mapbox_session} requests #{mapbox_requests}/#{mapbox_max}")

      if city_query == ""
        if htmx_request == 1
          return response.headers["HX-Redirect"] = "/maps"
        else
          return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
        end
      end

      if mapbox_requests >= mapbox_max # throttle
        if htmx_request == 1
          return response.headers["HX-Redirect"] = "/maps"
        else
          response.status = 429
          return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
        end
      end

      city_query = ::Service::Database::Query.normalize(query: city_query, default_field: "name", default_match: "like")
      resolve_result = ::Service::City::Resolve.new(query: city_query, offset: 0, limit: 5).call

      if resolve_result.code != 0
        if htmx_request == 1
          return response.headers["HX-Redirect"] = "/maps"
        else
          response.status = 404
          return view("maps/city/show", layout: "layouts/app", locals: {city: nil})
        end
      end

      city = resolve_result.city

      if htmx_request == 1
        response.headers["HX-Redirect"] = "/maps/city/#{city.id}"
      else
        r.redirect("/maps/city/#{city.id}")
      end
    end
  end
end