# frozen_string_literal: true

module Api
  module V1
    module Map
      class Tileset

        def initialize(request:, response:)
          @request = request
          @response = response

          @params = @request.params
          @city_id = @params["city_id"].to_s # can be city id or name
          @query = @params["q"].to_s
          @lat = @params["lat"]
          @lon = @params["lon"]

          @response.status = 200
        end

        def call
          # search places by city name; add support for radius search

          resolve_result = ::Service::City::Resolve.new(query: @city_id, offset: 0, limit: 5).call
          city = resolve_result.city

          if city
            search_results = ::Service::Places::Search.new(
              query: @query,
              near: city,
              offset: 0,
              limit: 100,
            ).call

            features = search_results.places.map do
              |place| place.geo_json_compact(color: ::Service::Places::Tags.tag_color(tags: place.tags))
            end
          else
            features = []
          end

          {
            "type"=>"FeatureCollection",
            "features" => features,
          }
        end

      end
    end
  end
end
