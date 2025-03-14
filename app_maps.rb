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

    # GET /maps/box/:box_name - html or htmx
    r.get "box", String do |box_name|
      query_raw = r.params["q"].to_s

      resolve_result = ::Service::Geo::Find.new(query: box_name).call

      if resolve_result.code != 0
        return r.redirect("/maps")
      end

      box = resolve_result.box

      tags_list = ::Service::Geo::Tags.tags_set_by_box(box: box).sort
      tags_color = tags_list.inject({}) { |d, tag| d[tag] = ::Service::Places::Tags.tag_color(tags: [tag]); d}
      tags_cur = tags_list.to_a.select{ |tag| query_raw.include?(tag) }.to_a.sort

      if not box
        response.status = 422
        return view(
          "maps/box/show",
          layout: "layouts/app",
          locals: {
            box: box,
            query_raw: query_raw,
            request_path: r.path,
            tags_color: tags_color,
            tags_cur: tags_cur,
            tags_list: tags_list,
        })
      end

      Console.logger.info(self, "maps box '#{box.name}' zoom #{box.map_zoom} mapbox session #{mapbox_session} requests #{mapbox_requests}/#{mapbox_max}")

      if mapbox_requests >= mapbox_max # throttle
        response.status = 429
        return view(
          "maps/city/show",
          layout: "layouts/app",
          locals: {
            city: city,
            mapbox_token: mapbox_token,
            query_raw: query_raw,
            request_path: r.path,
            tags_color: tags_color,
            tags_cur: tags_cur,
            tags_list: tags_list,
          })
      end

      r.session["mapbox_requests"] = mapbox_requests + 1

      if htmx_request == 0
        view(
          "maps/box/show",
          layout: "layouts/app",
          locals: {
            box: box,
            mapbox_token: mapbox_token,
            query_raw: query_raw,
            request_path: r.path,
            tags_color: tags_color,
            tags_cur: tags_cur,
            tags_list: tags_list,
          })
      else
        # update browser history
        response.headers["HX-Push-Url"] = "#{r.path}"

        # render without layout
        render("maps/box/show_map", locals: {
          box: box,
          mapbox_token: mapbox_token,
          query_raw: query_raw,
          request_path: r.path,
          tags_color: tags_color,
          tags_cur: tags_cur,
          tags_list: tags_list,
        })
      end
    end

    # GET /maps?box=paris html or htmx
    r.get do
      box_query = r.params["box"].to_s

      Console.logger.info(self, "maps query '#{box_query}' mapbox session #{mapbox_session} requests #{mapbox_requests}/#{mapbox_max}")

      city_names = ::Model::Place.select(:city).distinct(:city).all().map{ |o| o.city.slugify }.sort
      region_names = ::Model::Region.select(:name).all().map{ |o| o.name.slugify }.sort

      app_name = "Maps"

      if box_query == ""
        return view(
          "maps/index",
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city_names: city_names,
            region_names: region_names,
            request_path: r.path,
          },
        )
      end

      geo_result = ::Service::Geo::Find.new(query: box_query).call
      box = geo_result.box

      if not box
        city_result = ::Service::City::Resolve.new(query: box_query).call
        box = city_result.city

        # todo - resolve region if no city found
      end

      if box
        return response.headers["HX-Redirect"] = "/maps/box/#{box.name_slug}"
      else
        return response.headers["HX-Redirect"] = "/maps"
      end
    end
  end
end