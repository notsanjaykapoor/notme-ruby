# frozen_string_literal: true

module Service
  module City
    class Resolve

      def initialize(query:, offset:, limit:)
        @query = query.to_s
        @offset = offset
        @limit = limit

        @struct = Struct.new(:code, :city, :errors)
      end

      def call
        struct = @struct.new(0, nil, [])

        Console.logger.info(self, "#{Thread.current[:rid]} query '#{@query}'")

        search_result = ::Service::City::Search.new(query: @query, offset: 0, limit: 5).call

        if search_result.cities.length > 0
          struct.city = search_result.cities[0]
          return struct
        end

        # geocode city
        geocode_result = Geocoder.search(@name)

        if geocode_result.length == 0
          struct.code = 404
          return struct
        end

        update_result = ::Service::City::Update.new(data: geocode_result[0].data).call
        struct.city = update_result.city

        struct
      end

    end
  end
end

