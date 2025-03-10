# frozen_string_literal: true

# docs: https://docs.mapbox.com/api/search/geocoding/#forward-geocoding-with-structured-input

module Service
  module Mapbox
    class GeoForward

      def initialize(city:, street:)
        @city = city
        @street = street

        @token = ENV["MAPBOX_TOKEN"]
        @endpoint = "https://api.mapbox.com/search/geocode/v6/forward"
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
            address_line1: @street, # street name with number
            place: @city, # cities, villages, municipalities, etc
            language: @language,
          }

          response = @http.get(@endpoint, params: params)

          struct.data = JSON.parse(response.body)

          if response.code != 200
            struct.code = response.code
            struct.errors.append(struct.data.fetch("error"))
          end          
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
    