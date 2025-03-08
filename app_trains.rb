class AppTrains < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  route do |r|
    app_name = "Trains"
    app_version = ENV["APP_VERSION"] || ENV["RACK_ENV"]
    current_span = OpenTelemetry::Trace.current_span
    htmx_request = r.headers["HX-Request"] ? 1 : 0

    # GET /trains/search/breadth - html or htmx
    r.get "search", "breadth" do
      ::Service::Neo::session do |session|
        if htmx_request == 1
          city_from = r.params.fetch("city_from", "")
          max_changes = (r.params.fetch("max_changes", -1)).to_i

          Console.logger.info(self, "#{Thread.current[:rid]} all cities reachable from '#{city_from}' max #{max_changes} changes")

          if city_from != "" and max_changes > -1
            query = "nodes:#{city_from}:#{max_changes+1}"
            search_results = ::Service::City::Neo.search(session: session, query: query)
            paths = search_results.paths
          else
            query = nil
            paths = 0
          end

          # render partial view
          if query
            render("trains/list_table", locals: {paths: paths, query: query})
          else
            render("trains/list_error", locals: {message: "invalid query"})
          end
        else
          city_nodes= ::Service::City::Neo::cities_all(session: session)
          city_names = city_nodes.map{ |n| n.values[0].properties.dig(:name) }.sort

          app_name = "All Train Destinations"

          # render full view
          view(
            "trains/search/breadth",
            layout: "layouts/app",
            locals: {
              app_name: app_name,
              app_version: app_version,
              city_names: city_names,
              request_path: r.path,
          })
        end
      end
    end

    # GET /trains/search/shortest - html or htmx
    r.get "search", "shortest" do
      ::Service::Neo::session do |session|
        if htmx_request == 1
          city_from = r.params.fetch("city_from", "")
          city_to = r.params.fetch("city_to", "")
          max_changes = (r.params.fetch("max_changes", -1)).to_i

          Console.logger.info(self, "#{Thread.current[:rid]} shortest routes from '#{city_from}' to '#{city_to}' max #{max_changes} changes")

          if city_from != "" and city_to != "" and max_changes > -1
            query = "paths:#{city_from}:#{city_to}:#{max_changes+1}"
            search_results = ::Service::City::Neo.search(session: session, query: query)
            paths = search_results.paths
          else
            query = nil
            paths = 0
          end

          # render partial view
          if query
            render("trains/list_table", locals: {paths: paths, query: query})
          else
            render("trains/list_error", locals: {message: "invalid query"})
          end
        else
          city_nodes= ::Service::City::Neo::cities_all(session: session)
          city_names = city_nodes.map{ |n| n.values[0].properties.dig(:name) }.sort
  
          app_name = "Shortest Train Routes"

          # render full view
          view(
            "trains/search/shortest",
            layout: "layouts/app",
            locals: {
              app_name: app_name,
              app_version: app_version,
              city_names: city_names,
              request_path: r.path,
            })
        end
      end
    end

    # GET /trains - html or htmx
    r.get do
      query_raw = r.params["q"].to_s

      current_span.add_attributes({
        "app.htmx" => htmx_request,
        "app.request_id" => Thread.current[:rid],
        "app.query" => query_raw,
        "app.version" => app_version,
      })

      Console.logger.info(self, "#{Thread.current[:rid]} query '#{query_raw}'")

      ::Service::Neo::session do |session|
        if query_raw.match(/^(city|country):/)
          table = "cities"
          search_results = ::Service::City::Neo.nodes_search(session: session, query: query_raw)
          cities = search_results.map do |r|
            ::Model::City.find(name: r["node"][:name])
          end
        elsif query_raw.match(/^(nodes?:)|(paths?:)/)
          table = "paths"
          search_results = ::Service::City::Neo.search(session: session, query: query_raw)
          paths = search_results.paths
        else
          # default view
          table = ""
          cities = []
          paths = []
        end

        search_algos = [
          { 
            "name": "shortest paths between cities",
            "path": "/trains/search/shortest",
          },
          {
            "name": "all destinations from city",
            "path": "/trains/search/breadth",
          }
        ]

        if htmx_request == 1
          # update browser history
          response.headers["HX-Push-Url"] = "/graph?q=#{query_raw}"

          # render partial view
          if table == "cities"
            render("graph/cities/list_table", locals: {cities: cities, query: query_raw})
          elsif table == "paths"
            render("graph/paths/list_table", locals: {paths: paths, query: query_raw})
          end
        else
          # render full view
          view(
            "trains/list",
            layout: "layouts/app",
            locals: {
              app_name: app_name,
              app_version: app_version,
              cities: cities,
              paths: paths,
              query: query_raw,
              search_algos: search_algos,
              table: table,
            })
        end
      end
    end

  end
end