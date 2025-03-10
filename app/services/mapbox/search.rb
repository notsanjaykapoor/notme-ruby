# frozen_string_literal: true

require "cgi"

# docs: https://docs.mapbox.com/api/search/search-box/
# docs: https://docs.mapbox.com/api/search/search-box/#interactive-search
# docs: https://docs.mapbox.com/api/search/search-box/#search-request
# docs: https://docs.mapbox.com/api/search/search-box/#reverse-lookup

module Service
  module Mapbox
    class Search

      def initialize(city:, query:, limit:)
        @city = city
        @query = query

        @endpoint_suggest = "https://api.mapbox.com/search/searchbox/v1/suggest" # used
        @endpoint_forward = "https://api.mapbox.com/search/searchbox/v1/forward" # get lots of 206 results
        @endpoint_geo = "https://api.mapbox.com/search/geocode/v6/forward" # used
        @endpoint_reverse = "https://api.mapbox.com/search/searchbox/v1/reverse" # used
        @http = ::Service::Mapbox::Http.instance

        @bbox = [@city.lon_min, @city.lat_min, @city.lon_max, @city.lat_max].join(",")
        @language = "en"
        @limit = [limit, 10].min  # mapbox limit is 10
        @poi_category = ""
        @proximity = "#{@city.lon},#{@city.lat}"
        @session_token = ULID.generate
        @token = ENV["MAPBOX_TOKEN"]
        @types = "poi" 

        @struct = Struct.new(:code, :data, :errors)
      end

      def call
        struct = @struct.new(0, {}, [])

        Console.logger.info(self, "#{Thread.current[:rid]} query '#{@query}' near '#{@city.name}'")

        begin
          if match = @query.match(/lat_lon:(.+)/)
            # reverse lookup
            lat, lon = match[1].split(",")

            params = {
              access_token: @token, # required
              latitude: lat, # required
              longitude: lon, # required
              limit: @limit,
              types: @types,
            }

            response = @http.get(@endpoint_reverse, params: params)
            data = JSON.parse(response.body)
          elsif match = @query.match(/address:(.+)/)
            # geo address lookup
            address = match[1]

            params = {
              access_token: @token, # required
              address_line1: address, # street name with number
              place: @city.name, # cities, villages, municipalities, etc
              language: @language,
              limit: @limit,
            }
  
            response = @http.get(@endpoint_geo, params: params)
            data = JSON.parse(response.body)
          else
            # suggest endpoint

            if match = @query.match(/(.*)((category|categories):.+)/)
              # query contains a category
              @query = match[1]
              category_ids = match[2].split(":")[1]
              @poi_category = category_ids.split(",").map{ |s| s.strip }
            end

            params = {
              q: @query, # required
              access_token: @token, # required
              session_token: @session_token, # required for suggest
              bbox: @bbox,
              language: @language,
              limit: @limit,
              poi_category: @poi_category,
              proximity: @proximity,
              types: @types,
            }

            response = @http.get(@endpoint_suggest, params: params)
            data = JSON.parse(response.body)
          end

          if response.code == 206
            struct.code = response.code
            struct.errors.append("query '#{@query}' - 206 partial content")
          elsif response.code != 200
            struct.code = response.code
            struct.errors.append(data.fetch("error") || "mapbox return code #{response.code}")

            return struct
          end

          if features = data.fetch("features", nil)
            # most common return structure
            struct.data = features.map{ |o| o.dig("properties") }
          else
            # returned from suggest endpoint
            struct.data = data.dig("suggestions")
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
    