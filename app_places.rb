class AppPlaces < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  PAGE_LIMIT_DEFAULT = 20

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
          places_brands_path: "/places/#{place.id}/brands",
          places_notes_path: "/places/#{place.id}/notes",
          places_tags_path: "/places/#{place.id}/tags",
          places_website_path: "/places/#{place.id}/website",
          referer_path: referer_path,
        })
    end

    # GET /places/id/brands/add|remove - htmx
    # note: put, post throw "NoMethodError: undefined method 'value=' for an instance of Async::Variable"
    r.get Integer, "brands", String do |place_id, brands_op|
      place = ::Model::Place::find(id: place_id)

      if not place
        return response.headers["HX-Redirect"] = "/places"
      end

      print("params ", r.params) #

      brands_op = r.path.split("/")[-1]
      brands_mod = r.params["brands"].to_s.split(",").map{ |s| s.strip }

      Console.logger.info(self, "place #{place.id} brands '#{brands_op}' '#{brands_mod}'")

      case brands_op
      when "add"
        brands = (place.brands.to_set + brands_mod.to_set).to_a
      when "remove"
        brands = (place.brands.to_set - brands_mod.to_set).to_a
      end

      place.update(
        brands: brands,
        updated_at: Time.now.utc,
      )

      render(
        "places/edit_brands",
        layout: "layouts/app",
        locals: {
          place: place,
          places_brands_path: "/places/#{place.id}/brands",
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

    # GET /places/id/tags/add|remove - htmx
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
          places_tags_path: "/places/#{place.id}/tags",
        })
    end

    # GET /places/id/website - htmx
    # note: put, post throw "NoMethodError: undefined method 'value=' for an instance of Async::Variable"
    r.get Integer, "website" do |place_id|
      place = ::Model::Place::find(id: place_id)

      if not place
        return response.headers["HX-Redirect"] = "/places"
      end

      Console.logger.info(self, "place #{place.id} website update")

      website_new = r.params["val"].to_s.strip

      place.website = website_new
      place.save

      "saved"
    end

    # GET /places/box/chicago/create - htmx
    r.get "box", String, "create" do |box_name|
      resolve_result = ::Service::Geo::Find.new(query: box_name).call
      box = resolve_result.box

      if !box.is_a?(::Model::City)
        # box should always be a city
        return response.headers["HX-Redirect"] = "/places/box/#{box.name_slug}"
      end

      name = r.params["name"].to_s

      Console.logger.info(self, "place create name '#{name}' box '#{box.name}'")

      create_result = ::Service::Places::CreateFromManual.new(
        name: name,
        city: box,
      ).call

      if create_result.code == 0
        place = create_result.places[0]

        redirect_path = "/places/#{place.id}/edit"
      else
        redirect_path = "/places/box/#{box.name_slug}"
      end

      return response.headers["HX-Redirect"] = redirect_path
    end

    # GET /places/box/chicago/new - htmx
    r.get "box", String, "new" do |box_name|
      resolve_result = ::Service::Geo::Find.new(query: box_name).call
      box = resolve_result.box
  
      # render without layout
      render(
        "places/new",
        locals: {
          box: box,
        }
      )
    end

    # GET /places/box/:box_name?q=tags:food - html or htmx
    r.get "box", String do |box_name|
      limit = r.params.fetch("limit", 20).to_i
      offset = r.params.fetch("offset", 0).to_i

      resolve_result = ::Service::Geo::Find.new(query: box_name).call

      if resolve_result.code != 0
        return r.redirect("/places")
      end

      box = resolve_result.box

      query = r.params["q"].to_s
      query = ::Service::Database::Query.normalize(
        query: query,
        default_field: "name",
        default_match: "like",
      )

      search_result = ::Service::Places::Search.new(
        query: query,
        box: box,
        offset: offset,
        limit: limit,
      ).call

      places_list = search_result.places
      places_total = search_result.total

      tags_cur = search_result.tags
      tags_list = ::Service::Geo::Tags.tags_set_by_box(box: box).sort

      brands_cur = search_result.brands
      brands_list = ::Service::Geo::Brands.brands_set_by_box(box: box).sort
      brands_show = ::Service::Geo::Brands.brands_flag(tags: tags_cur)

      app_name = "Places in '#{box.name}'"

      mapbox_path = "/mapbox/city/#{box.name_slug}"
      places_path = r.path

      page_prev, page_next = page_paths(path: r.path, params: r.params, offset: offset, limit: limit, total: places_total)

      if htmx_request == 0
        view(
          "places/list", 
          layout: "layouts/app",
          locals: {
            app_name: app_name,
            app_version: app_version,
            box: box,
            brands_cur: brands_cur,
            brands_list: brands_list,
            brands_show: brands_show,
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
            box: box,
            brands_cur: brands_cur,
            brands_list: brands_list,
            brands_show: brands_show,
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
          }
        )
      end
    end

    # GET /places?q=city:chicago
    # GET /places?q=tags:food
    r.get do
      limit = r.params.fetch("limit", PAGE_LIMIT_DEFAULT).to_i
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

      box_name = search_result.city_name

      if box_name != ""
        # redirect to city/region view
        box_path = "/places/box/#{box_name.slugify}"

        if htmx_request == 0
          return r.redirect(box_path)
        else
          return response.headers["HX-Redirect"] = box_path
        end
      end

      places_list = search_result.places
      places_total = search_result.total

      tags_cur = search_result.tags
      tags_list = ::Service::Geo::Tags.tags_set_all.sort

      brands_cur = search_result.brands
      brands_list = ::Service::Geo::Brands.brands_set_all.sort
      brands_show = ::Service::Geo::Brands.brands_flag(tags: tags_cur)

      city_names = ::Model::Place.select(:city).distinct(:city).all().map{ |o| o.city.slugify }.sort
      region_names = ::Model::Region.select(:name).all().map{ |o| o.name.slugify }.sort

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
            box: nil,
            brands_cur: brands_cur,
            brands_list: brands_list,
            brands_show: brands_show,
            city_names: city_names,
            limit: limit,
            offset: offset,
            page_next: page_next,
            page_prev: page_prev,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            places_query_example: "places search - e.g. tags:food",
            region_names: region_names,
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
            box: nil,
            brands_cur: brands_cur,
            brands_list: brands_list,
            brands_show: brands_show,
            city_names: city_names,
            limit: limit,
            offset: offset,
            page_next: page_next,
            page_prev: page_prev,
            places_list: places_list,
            places_path: places_path,
            places_query: query,
            region_names: region_names,
            tags_cur: tags_cur,
            tags_list: tags_list,
            total: places_total,
          })
      end
    end
  end
end