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

    r.session["mapbox_session"] ||= ULID.generate
    mapbox_session = r.session["mapbox_session"]
    mapbox_requests = (r.session["mapbox_requests"] || 0).to_i

    # GET /maps/city/:id, html or htmx
    r.get "city", String do |city_id|
      query = r.params["q"].to_s

      if city_id.match(/^\d+$/)
        city_query = "id:#{city_id}"
      else
        city_query = "name:~#{city_id}"
      end

      search_result = ::Service::City::Search.new(
        query: city_query,
        offset: 0,
        limit: 1,
      ).call

      city = search_result.cities[0]

      tags_list = ::Service::City::Tags.tags_set_by_city(city_name: city.name).sort
      tags_color = tags_list.inject({}) { |d, tag| d[tag] = ::Service::Places::Tags.tag_color(tags: [tag]); d}
      tags_cur = tags_list.to_a.select{ |tag| query.include?(tag) }.to_a.sort

      if not city
        response.status = 422
        return view(
          "maps/city/show",
          layout: "layouts/app",
          locals: {
            city: nil,
            query: "",
            request_path: r.path,
            tags_cur: tags_cur,
            tags_list: tags_list,
        })
      end

      Console.logger.info(self, "city #{city.name} mapbox session #{mapbox_session} requests #{mapbox_requests}/#{mapbox_max}")

      if mapbox_requests >= mapbox_max # throttle
        response.status = 429
        return view(
          "maps/city/show",
          layout: "layouts/app",
          locals: {
            city: city,
            query: query,
            request_path: r.path,
            tags_color: tags_color,
            tags_cur: tags_cur,
            tags_list: tags_list,
          })
      end

      r.session["mapbox_requests"] = mapbox_requests + 1

      if htmx_request == 0
        view(
          "maps/city/show",
          layout: "layouts/app",
          locals: {
            city: city,
            mapbox_token: mapbox_token,
            query: query,
            request_path: r.path,
            tags_color: tags_color,
            tags_cur: tags_cur,
            tags_list: tags_list,
          })
      else
        # update browser history
        response.headers["HX-Push-Url"] = "#{r.path}"

        # render without layout
        render("maps/city/show_map", locals: {
          city: city,
          mapbox_token: mapbox_token,
          query: query,
          request_path: r.path,
          tags_color: tags_color,
          tags_cur: tags_cur,
          tags_list: tags_list,
        })
      end
    end

    # GET /maps, optional city=name param, html or htmx
    r.get do
      city_query = r.params["city"].to_s

      Console.logger.info(self, "query '#{city_query}' mapbox session #{mapbox_session} requests #{mapbox_requests}/#{mapbox_max}")

      city_names = ::Model::Place.select(:city).distinct(:city).all().map{ |o| o.city.slugify }.sort

      app_name = "Maps"

      if city_query == ""
        return view(
          "maps/index",
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city_names: city_names,
            request_path: r.path,
          },
        )
      end

      resolve_result = ::Service::City::Resolve.new(query: city_query, offset: 0, limit: 5).call
      city = resolve_result.city

      if city
        return response.headers["HX-Redirect"] = "/maps/city/#{city.name_slug}"
      else
        return response.headers["HX-Redirect"] = "/maps"
      end
    end
  end
end