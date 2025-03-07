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
          places_city_path: "/places/city/#{place.city_slug}",
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
      places_total = search_result.total

      tags_set_cur = search_result.tags.to_set
      tags_list_new = (::Service::City::Tags.tags_set_by_city(city_name: city.name) - tags_set_cur).to_a.sort

      app_name = "Places near '#{city.name}'"

      mapbox_path = "/mapbox/city/#{city.name_slug}"
      places_path = r.path

      if htmx_request == 0
        view(
          "places/list", 
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city: city,
            mapbox_path: mapbox_path,
            places_count: places_count,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            places_query_example: "place search - e.g. tags:food",
            places_total: places_total,
            tags_list: tags_list_new,
          },
        )
      else
        # update browser history
        response.headers["HX-Push-Url"] = "/places?q=#{query}"

        # render without layout
        render(
          "places/list_table",
            locals: {
            city: city,
            mapbox_path: mapbox_path,
            places_count: places_count,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            places_total: places_total,
            tags_list: tags_list_new,
          })
      end
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
        limit: 20,
      ).call

      places_list = search_result.places
      places_count = places_list.length
      places_total = search_result.total

      city_name = search_result.city_name

      if city_name != ""
        # redirect to city view
        city_path = "/places/city/#{city_name.slugify}"

        if htmx_request == 0
          return r.redirect()
        else
          return response.headers["HX-Redirect"] = city_path
        end
      end

      tags_set_cur = search_result.tags.to_set
      tags_list_new = (::Service::City::Tags.tags_set_all - tags_set_cur).to_a.sort

      places_path = r.path

      city_names = ::Model::Place.select(:city).distinct(:city).all().map{ |o| o.city.slugify }.sort

      if htmx_request == 0
        view(
          "places/list", 
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city: nil,
            city_names: city_names,
            places_count: places_count,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            places_query_example: "places search - e.g. tags:food, city:chicago",
            places_total: places_total,
            tags_list: tags_list_new,
          },
        )
      else
        # update browser history
        response.headers["HX-Push-Url"] = "#{r.path}?q=#{query}"

        # render without layout
        render("places/list_table", locals: {
          city: nil,
          city_names: city_names,
          places_count: places_count,
          places_list: places_list,
          places_path: places_path,
          places_query: query,
          places_total: places_total,
          tags_list: tags_list_new,
        })
      end
    end
  end
end