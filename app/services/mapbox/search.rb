# frozen_string_literal: true

require "cgi"

# docs: https://docs.mapbox.com/api/search/search-box/

module Service
  module Mapbox
    class Search

      def initialize(city:, query:, limit: 10)
        @city = city
        @query = CGI.escape(query)

        @token = ENV["MAPBOX_TOKEN"]
        @endpoint = "https://api.mapbox.com/search/searchbox/v1/suggest"
        @limit = [limit, 10].min  # mapbox limit is 10
        @session_token = ULID.generate()
        @proximity = "#{city.lon},#{city.lat}"
        @http = ::Service::Mapbox::Http.instance

        @struct = Struct.new(:code, :data, :errors)
      end

      def call
        struct = @struct.new(0, {}, [])

        Console.logger.info(self, "#{Thread.current[:rid]} query '#{@query}'")

        begin
          params = {
            q: @query, # required
            access_token: @token, # required
            session_token: @session_token, # required
            limit: @limit,
            proximity: @proximity,
          }

          response = @http.get(@endpoint, params: params)

          if response.code != 200
            struct.code = response.code

            return struct
          end

          struct.data = JSON.parse(response.body).dig("suggestions")
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
    