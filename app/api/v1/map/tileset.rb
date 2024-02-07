# frozen_string_literal: true

module Api
  module V1
    module Map
      class Tileset

        def initialize(request:, response:)
          @request = request
          @response = response

          @params = @request.params
          @city_id = @params["city_id"].to_i
          @city = @params["city"]
          @lat = @params["lat"]
          @lon = @params["lon"]

          @response.status = 200
        end

        def call
          # search places by city name; add support for radius search
          if @city_id > 0
            query = "city:#{@city_id}"
          else
            query = "city:~#{@city}"
          end

          search_results = ::Service::Places::Search.new(
            query: query,
            offset: 0,
            limit: 100,
          ).call

          features = search_results.places.map { |place| place.geo_json_compact }

          {
            "type"=>"FeatureCollection",
            "features" => features,
          }
        end

      end
    end
  end
end
