class AppMapbox < Roda
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

    # POST /mapbox/city/:city_name/add?mapbox_id=xxxx - htmx
    r.post "city", String, "add" do |city_name|
      mapbox_id = r.params["mapbox_id"].to_s

      resolve_result = ::Service::City::Resolve.new(query: city_name, offset: 0, limit: 5).call
      city = resolve_result.city

      if not city
        return response.headers["HX-Redirect"] = "/places"
      end

      Console.logger.info(self, "mapbox city '#{city.name_lower}' add '#{mapbox_id}'")

      create_result = ::Service::Places::CreateFromMapbox.new(mapbox_id: mapbox_id, mapbox_session: mapbox_session).call

      if create_result.code != 0
        # todo
      end

      place = create_result.places[0]

      return response.headers["HX-Redirect"] = "/places/#{place.id}/edit"
    end

    # GET /mapbox/city/:city_name?q=food - html or htmx
    r.get "city", String do |city_name|
      query = URI.decode_www_form_component(r.params["q"].to_s)

      resolve_result = ::Service::City::Resolve.new(query: city_name, offset: 0, limit: 5).call
      city = resolve_result.city

      if not city
        # redirect to places
        return response.headers["HX-Redirect"] = "/places"
      end

      Console.logger.info(self, "mapbox city '#{city.name_lower}' search '#{query}'")

      if query == ""
        # redirect to city places
        return response.headers["HX-Redirect"] = "/places/city/#{city.name_slug}"
      end

      search_result = ::Service::Mapbox::Search.new(city: city, query: query, limit: 10).call
      mapbox_code = search_result.code
      mapbox_errors = search_result.errors
      mapbox_list = search_result.data

      mapbox_list.each_with_index do |data, index|
        puts index+1
        puts data
        puts
      end

      mapbox_ids = ::Model::Place.select(:source_id).all.map{ |o| o.source_id }.to_set

      app_name = "Mapbox List"

      if htmx_request == 0
        # invalid
      else
        render(
          "mapbox/list_table",
          locals: {
            city: city,
            mapbox_code: mapbox_code,
            mapbox_errors: mapbox_errors,
            mapbox_ids: mapbox_ids,
            mapbox_list: mapbox_list,
            mapbox_path: r.path,
            mapbox_query: query,
          })
      end
    end
  end
end