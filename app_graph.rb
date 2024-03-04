class AppGraph < Roda
  plugin :all_verbs
  plugin :hooks
  plugin :json, serializer: ::Oj.method(:dump)
  plugin :json_parser, parser: ::Oj.method(:load)
  plugin :request_headers
  plugin :render
  plugin :sessions, secret: ENV["APP_SECRET"]

  route do |r|
    app_name = "Graph"
    app_version = ENV["APP_VERSION"] || ENV["RACK_ENV"]
    htmx_request = r.headers["HX-Request"] ? 1 : 0

    # GET /graph - html or htmx
    r.get do
      query_raw = r.params["q"].to_s

      Console.logger.info(self, "query '#{query_raw}'")

      ::Service::Neo::session do |session|
        if query_raw.match(/^(city|country):/) or not query_raw.match(/:/)
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
          # default
          table = "cities"
          cities = []
        end

        if htmx_request == 1
          if table == "cities"
            render("graph/cities/table", locals: {cities: cities, query: query_raw})
          elsif table == "paths"
            render("graph/paths/table", locals: {paths: paths, query: query_raw})
          end
        else
          view("graph/cities/index", layout: "layouts/app", locals: {
            app_name: app_name,
            app_version: app_version,
            cities: cities,
            query: query_raw,
            table: table,
          })
        end
      end
    end

  end
end