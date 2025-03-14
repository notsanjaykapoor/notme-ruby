# frozen_string_literal: true

module Service
  module Geo
    class Find
      #
      # Find matching city or region in the database.  If no matches are found return a 404.
      #

      def initialize(query:)
        @query = query.to_s

        @struct = Struct.new(:code, :box, :errors)
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

        # search cities first

        search_result = ::Service::City::Search.new(query: @query, offset: 0, limit: 5).call

        if search_result.cities.length == 1
          # found a unique city match
          struct.box = search_result.cities[0]
          return struct
        end

        if search_result.cities.length > 0
          # found multiple matches, pick the first one
          struct.box = search_result.cities[0]
          return struct
        end

        # search regions

        search_result = ::Service::Region::Search.new(query: @query, offset: 0, limit: 5).call

        if search_result.regions.length == 0
          struct.code = 404
          return struct
        end

        struct.box = search_result.regions[0]

        struct
      end

    end
  end
end

