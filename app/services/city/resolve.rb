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

        @address_types = ["city", "province"]
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
            @query = "name:#{@query}"
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
        geocode_results = Geocoder.search(match_result[1])

        if geocode_results.length == 0
          struct.code = 404
          return struct
        end

        # filter geocode results by addresstype
        geocode_results = geocode_results.select{ |o| @address_types.include?(o.data.fetch("addresstype", ""))}

        if geocode_results.length == 0
          struct.code = 404
          return struct
        end

        # sort cities over province
        geocode_results = geocode_results.sort_by { |o| o.data.fetch("addresstype") }

        geocode_data = geocode_results[0].data
        update_result = ::Service::City::Update.new(data: geocode_data).call

        struct.code = update_result.code
        struct.city = update_result.city

        struct
      end

    end
  end
end

