class AppPlaces < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  def page_paths(path:, params:, offset:, limit:, total:)
    params_next = params.tap do |d|
      if offset+limit < total
        d["offset"] = offset+limit
      else
        d.delete("offset")
      end
    end

    page_next = params_next.size > 0 ? "#{path}?#{params_next.to_query}" : path

    params_prev = params.tap do |d|
      if offset-limit > 0
        d["offset"] = offset-limit
      else
        d.delete("offset")
      end
    end

    page_prev = params_prev.size > 0 ? "#{path}?#{params_prev.to_query}" : path

    return page_prev, page_next
  end

  route do |r|
    app_version = ENV["APP_VERSION"] || ENV["RACK_ENV"]
    htmx_request = r.headers["HX-Request"] ? 1 : 0

    r.session["mapbox_session"] ||= ULID.generate

    # GET /places/id/edit
    r.get Integer, "edit" do |place_id|
      place = ::Model::Place::find(id: place_id)

      if not place
        return r.redirect("/places")
      end
      
      referer_path = r.referer

      app_name = "Place Edit"

      view(
        "places/edit",
        layout: "layouts/app",
        locals: {
          app_name: app_name,
          app_version: app_version,
          place: place,
          places_notes_path: "/places/#{place.id}/notes",
          places_tags_path: "/places/#{place.id}/tags",
          referer_path: referer_path,
        })
    end

    # GET /places/id/notes - htmx
    # note: put, post throw "NoMethodError: undefined method 'value=' for an instance of Async::Variable"
    r.get Integer, "notes" do |place_id|
      place = ::Model::Place::find(id: place_id)

      if not place
        return response.headers["HX-Redirect"] = "/places"
      end

      Console.logger.info(self, "place #{place.id} notes update")

      notes_new = r.params["val"].to_s.strip

      place.notes = notes_new
      place.save

      "saved"
    end

    # get /places/id/tags/add|remove - htmx
    # note: put, post throw "NoMethodError: undefined method 'value=' for an instance of Async::Variable"
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
          places_notes_path: "/places/#{place.id}/notes",
          places_tags_path: "/places/#{place.id}/tags",
        })
    end

    # GET /places/city/chicago?q=tags:food
    r.get "city", String do |city_name|
      limit = r.params.fetch("limit", 20).to_i
      offset = r.params.fetch("offset", 0).to_i

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
        offset: offset,
        limit: limit,
      ).call

      places_list = search_result.places
      places_total = search_result.total

      tags_cur = search_result.tags
      tags_list = ::Service::City::Tags.tags_set_by_city(city_name: city.name).sort

      app_name = "Places near '#{city.name}'"

      mapbox_path = "/mapbox/city/#{city.name_slug}"
      places_path = r.path

      page_prev, page_next = page_paths(path: r.path, params: r.params, offset: offset, limit: limit, total: places_total)

      if htmx_request == 0
        view(
          "places/list", 
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city: city,
            limit: limit,
            mapbox_path: mapbox_path,
            offset: offset,
            page_next: page_next,
            page_prev: page_prev,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            places_query_example: "place search - e.g. tags:food",
            tags_cur: tags_cur,
            tags_list: tags_list,
            total: places_total,
          })
      else
        # update browser history
        response.headers["HX-Push-Url"] = (query != "") ? "#{r.path}?q=#{query}" : r.path

        # render without layout
        render(
          "places/list_table",
            locals: {
            city: city,
            limit: limit,
            mapbox_path: mapbox_path,
            offset: offset,
            page_next: page_next,
            page_prev: page_prev,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            tags_cur: tags_cur,
            tags_list: tags_list,
            total: places_total,
          })
      end
    end

    # GET /places?q=city:chicago
    # GET /places?q=tags:food
    r.get do
      limit = r.params.fetch("limit", 10).to_i
      offset = r.params.fetch("offset", 0).to_i

      query = r.params["q"].to_s
      query = ::Service::Database::Query.normalize(
        query: query,
        default_field: "name",
        default_match: "like",
      )

      search_result = ::Service::Places::Search.new(
        query: query,
        offset: offset,
        limit: limit,
      ).call

      places_list = search_result.places
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

      tags_cur = search_result.tags
      tags_list = ::Service::City::Tags.tags_set_all.sort

      city_names = ::Model::Place.select(:city).distinct(:city).all().map{ |o| o.city.slugify }.sort

      places_path = r.path
      app_name = "Places"

      page_prev, page_next = page_paths(path: r.path, params: r.params, offset: offset, limit: limit, total: places_total)

      if htmx_request == 0
        view(
          "places/list", 
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            city: nil,
            city_names: city_names,
            limit: limit,
            offset: offset,
            page_next: page_next,
            page_prev: page_prev,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            places_query_example: "places search - e.g. tags:food, city:chicago",
            tags_cur: tags_cur,
            tags_list: tags_list,
            total: places_total,
          })
      else
        # update browser history
        response.headers["HX-Push-Url"] = (query != "") ? "#{r.path}?q=#{query}" : r.path

        # render without layout
        render(
          "places/list_table",
          locals: {
            city: nil,
            city_names: city_names,
            limit: limit,
            offset: offset,
            page_next: page_next,
            page_prev: page_prev,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            tags_cur: tags_cur,
            tags_list: tags_list,
            total: places_total,
          })
      end
    end
  end
end