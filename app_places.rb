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

    # move
    # POST /places/add?mapbox_id=xxx - htmx
    r.post "add" do
      mapbox_id = r.params["mapbox_id"].to_s
      create_result = ::Service::Places::CreateFrom.new(mapbox_id: mapbox_id, mapbox_session: mapbox_session).call

      if create_result.code != 0
        # todo
      end

      return render("places/mapbox/add_ok")
    end

    # GET /places/id/edit
    r.get Integer, "edit" do |place_id|
      place = ::Model::Place::find(id: place_id)

      if not place
        return r.redirect("/places")
      end
      
      app_name = "Place Edit"

      view(
        "places/edit",
        layout: "layouts/app",
        locals: {
          app_name: app_name,
          app_version: app_version,
          place: place,
          places_city_path: "places/city/#{place.city_slug}",
          places_tags_path: "/places/#{place.id}/tags",
        }
      )
    end

    # GET /places/id/tags/add|remove - htmx
    r.get Integer, "tags", String do |place_id, tags_op|
      place = ::Model::Place::find(id: place_id)

      if not place
        return response.headers["HX-Redirect"] = "/places"
      end

      tags_op = r.path.split("/")[-1]
      tags_mod = r.params["tags"].to_s.split(",").map{ |s| s.strip }

      Console.logger.info(self, "place #{place.id} tags '#{tags_op}' '#{tags_mod}'")

      case tags_op
      when "add"
        tags = (place.tags.to_set + tags_mod.to_set).to_a
      when "remove"
        tags = (place.tags.to_set - tags_mod.to_set).to_a
      end

      place.update(
        tags: tags,
        updated_at: Time.now.utc,
      )

      render(
        "places/edit_tags",
        layout: "layouts/app",
        locals: {
          place: place,
          places_tags_path: "/places/#{place.id}/tags",
        }
      )
    end

    # GET /places/city/chicago?q=tags:food
    r.get "city", String do |city_name|
      resolve_result = ::Service::City::Resolve.new(query: city_name, offset: 0, limit: 1).call

      if resolve_result.code != 0
        return r.redirect("/places")
      end

      city = resolve_result.city

      query = r.params["q"].to_s
      query = ::Service::Database::Query.normalize(
        query: query,
        default_field: "name",
        default_match: "like",
      )

      search_result = ::Service::Places::Search.new(
        query: query,
        near: city,
        offset: 0,
        limit: 50,
      ).call

      places_list = search_result.places
      places_count = places_list.length
      tags_list_cur = search_result.tags.to_set

      tags_list_all = ::Model::Place.where(city: city.name).select(:tags).all().inject(Set[]) { |s, o| s.merge(o.tags) }
      tags_list_new = (tags_list_all - tags_list_cur).to_a.sort

      app_name = "Places near '#{city.name}'"

      if htmx_request == 0
        view(
          "places/list", 
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city: city,
            places_count: places_count,
            places_list: places_list,
            places_path: r.path,
            query: query,
            query_example: "place search - e.g. tags:food",
            tags_list: tags_list_new,
          },
        )
      else
        # update browser history
        response.headers["HX-Push-Url"] = "/places?q=#{query}"

        # render without layout
        render("places/list_table", locals: {
          city: city,
          places_count: places_count,
          places_list: places_list,
          places_path: r.path,
          query: query,
          tags_list: tags_list_new,
        })
      end
    end

    # move
    # GET /places/mapbox/query?q=food+near:chicago - htmx
    r.get "mapbox/query" do
      mapbox_query = r.params["q"].to_s

      # extract location from query
      match_query = mapbox_query.match(/(.+) (near:[a-zA-z\-\s]+)/)

      if not match_query
        @error = "invalid search"
        return render("places/mapbox/query_error")
      end

      _, city_query = match_query[2].split(":")
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

    # GET /places?q=city:chicago
    # GET /places?q=tags:food
    r.get do
      app_name = "Places"

      query = r.params["q"].to_s
      query = ::Service::Database::Query.normalize(
        query: query,
        default_field: "name",
        default_match: "like",
      )

      search_result = ::Service::Places::Search.new(
        query: query,
        offset: 0,
        limit: 50,
      ).call

      places_list = search_result.places
      places_count = places_list.length
      tags_list_cur = search_result.tags.to_set

      tags_list_all = Model::Place.select(:tags).all().inject(Set[]) { |s, o| s.merge(o.tags) }
      tags_list_new = (tags_list_all - tags_list_cur).to_a.sort

      if htmx_request == 0
        view(
          "places/list", 
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city: nil,
            places_count: places_count,
            places_list: places_list,
            places_path: r.path,
            query: query,
            query_example: "places search - e.g. city:chicago, tags:food",
            tags_list: tags_list_new,
          },
        )
      else
        # update browser history
        response.headers["HX-Push-Url"] = "#{r.path}=#{query}"

        # render without layout
        render("places/list_table", locals: {
          city: nil,
          places_count: places_count,
          places_list: places_list,
          places_path: r.path,
          query: query,
          tags_list: tags_list_new,
        })
      end
    end
  end
end