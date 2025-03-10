# frozen_string_literal: true

# docs: https://docs.mapbox.com/api/search/search-box/#reverse-lookup

module Service
  module Mapbox
    class GeoReverse

      def initialize(lat:, lon:)
        @lat = lat
        @lon = lon

        @token = ENV["MAPBOX_TOKEN"]
        @endpoint = "https://api.mapbox.com/search/searchbox/v1/reverse"
        @http = ::Service::Mapbox::Http.instance
        @language = "en"

        @struct = Struct.new(:code, :data, :errors)
      end

      def call
        struct = @struct.new(0, {}, [])

        Console.logger.info(self, "#{Thread.current[:rid]} id '#{@id}'")

        begin
          params = {
            access_token: @token, # required
            latitude: @lat,
            longitude: @lon,
            language: @language,
          }

          response = @http.get(@endpoint, params: params)

          if response.code != 200
            struct.code = response.code

            return struct
          end

          struct.data = JSON.parse(response.body)
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
    