# frozen_string_literal: true

module Service
  module City
    class Resolve
      #
      # Resolve city object by first searching the database.  If a matching city is not found,
      # geocode the city name, filter results based on 'addresstype' and add to the database.
      #

      def initialize(query:)
        @query = query.to_s

        @struct = Struct.new(:code, :city, :errors)
      end

      def call
        struct = @struct.new(0, nil, [])

        Console.logger.info(self, "#{Thread.current[:rid]} query '#{@query}'")

        if !@query.include?(":")
          if @query.match(/^\d+$/)
            # normalize query with id tag
            @query = "id:#{@query}"
          else
            # normalize query with name tag
            @query = "name:#{@query.deslugify}"
          end
        end

        search_result = ::Service::City::Search.new(query: @query, offset: 0, limit: 5).call

        if search_result.cities.length > 0
          struct.city = search_result.cities[0]
          return struct
        end

        if not (match_result = @query.match(/^name:\~?([a-zA-Z\s]+)/))
          struct.code = 422
          return struct
        end

        # geocode city
        geocode_results = Service::Geo::Geocode.new(name: match_result[1], type: "city").call

        if geocode_results.features.length == 0
          struct.code = 404
          return struct
        end

        geo_json = geocode_results.features[0]
        update_result = ::Service::City::Update.new(name: geo_json.dig("properties", "name"), geo_json: geo_json).call

        struct.code = update_result.code
        struct.city = update_result.city

        struct
      end

    end
  end
end

