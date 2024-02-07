class AppPlaces < Roda
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

    # GET /places/search?q=chicago
    r.get "search" do
      query = r.params["q"].to_s
      query = ::Service::Database::Query.normalize(query: query, default_field: "name", default_match: "like")

      search_result = ::Service::Places::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      places_list = search_result.places
      places_count = places_list.length

      # render without layout
      render("places/list/table", locals: {places_count: places_count, places_list: places_list, query: query})
    end

    # POST /places/add?mapbox_id=xxx, htmx
    r.post "add" do
      mapbox_id = r.params["mapbox_id"].to_s
      create_result = ::Service::Places::CreateFrom.new(mapbox_id: mapbox_id, mapbox_session: mapbox_session).call

      if create_result.code != 0
        # todo
      end

      return render("places/mapbox/add_ok")
    end

    # GET /places/mapbox/query?q=food+near:chicago, htmx
    r.get "mapbox/query" do
      mapbox_query = r.params["q"].to_s

      # extract location from query
      match_query = mapbox_query.match(/(.+) (near:[a-zA-z\-\s]+)/)

      if not match_query
        @error = "invalid search"
        return render("places/mapbox/query_error")
      end

      _, city_query = match_query[2].split(":")
      city_query = ::Service::Database::Query.normalize(query: city_query, default_field: "name", default_match: "like")
      resolve_result = ::Service::City::Resolve.new(query: city_query, offset: 0, limit: 5).call

      if resolve_result.code != 0
        @error = "invalid location"
        return render("places/mapbox/query_error")
      end

      city = resolve_result.city
      query = match_query[1]

      search_result = ::Service::Mapbox::Search.new(city: city, query: query, limit: 10, session: mapbox_session).call
      mapbox_list = search_result.data

      # mapbox_list = [
      #   {
      #     "name" => "Au Cheval",
      #     "full_address" => "800 W Randolph St",
      #     "feature_type" => "poi",
      #     "mapbox_id"=>"dXJuOm1ieHBvaTo2YWYzNGVjZi0yNTFjLTRiMDMtYmMwNS01MGE0NDk0ZDkwMzg",
      #     "poi_category"=>["coworking space", "office"]",
      #   },
      #   {
      #     "name" => "Random Spot",
      #     "full_address" => "801 W Randolph St",
      #     "feature_type" => "poi",
      #     "mapbox_id"=>"dXJuOm1ieHBvaTo2YWYzNGVjZi0yNTFjLTRiMDMtYmMwNS01MGE0NDk0ZDkwMxx",
      #     "poi_category"=>["coworking space", "office"]","
      #   },
      # ]

      mapbox_list.each_with_index do |data, index|
        puts index+1
        puts data
        puts
      end

      mapbox_ids = ::Model::Place.select(:source_id).all.map{ |o| o.source_id }.to_set

      render("places/mapbox/table", locals: {mapbox_ids: mapbox_ids, mapbox_list: mapbox_list})
    end

    # GET /places/mapbox, html
    r.get "mapbox" do
      text = "Mapbox Search"

      view("places/mapbox/index", layout: "layouts/app", locals: {app_version: app_version, text: text})
    end

    # GET /places
    r.get do
      app_name = "Places"
      query = ""

      search_result = ::Service::Places::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      places_list = search_result.places
      places_count = places_list.length

      view(
        "places/list/index", 
        layout: "layouts/app",
        locals: {app_name: app_name, app_version: app_version, places_count: places_count, places_list: places_list, query: query},
      )
    end
  end
end