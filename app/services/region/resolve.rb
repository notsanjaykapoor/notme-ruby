# frozen_string_literal: true

module Service
  module Region
    class Resolve
      #
      # Resolve region object by first searching the database.  If a matching region is not found,
      # geocode the region name, filter results based on 'addresstype' and add to the database.
      #

      def initialize(query:)
        @query = query.to_s

        @address_types = {
          "country" => 1,
          "continent" => 2,
        }
        @struct = Struct.new(:code, :region, :errors)
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

        search_result = ::Service::Region::Search.new(query: @query, offset: 0, limit: 5).call

        if search_result.regions.length > 0
          struct.region = search_result.regions[0]
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
        geocode_results = geocode_results.select{ |o| @address_types.keys.include?(o.data.fetch("addresstype", ""))}

        if geocode_results.length == 0
          struct.code = 404
          return struct
        end

        # sort results by addresstype
        geocode_results = geocode_results.sort_by { |o| @address_types.fetch(o.data.fetch("addresstype")) }

        geocode_data = geocode_results[0].data
        update_result = ::Service::Region::Update.new(data: geocode_data).call

        struct.code = update_result.code
        struct.region = update_result.region

        struct
      end

    end
  end
end

