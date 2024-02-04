# frozen_string_literal: true

module Api
  module V1
    module Map
      class Tileset

        def initialize(request:, response:)
          @request = request
          @response = response

          @params = @request.params
          @city = @params["city"]
          @lat = @params["lat"]
          @lon = @params["lon"]

          @response.status = 200
        end

        def call
          search_results = ::Service::Places::Search.new(
            query: "city:~#{@city}",
            offset: 0,
            limit: 100,
          ).call

          features = search_results.places.map { |place| place.geo_json_compact }

          {
            "type"=>"FeatureCollection",
            "features" => features,
          }
          # struct_retrieve = ::Service::Mapbox::Retrieve.new(
          #     id: "dXJuOm1ieHBvaTo0NWZiZWE3Yi1hYTI3LTQ0NmItOTJlOC03MTlhYjliYmVhMTc"
          # ).call

          # struct_create = ::Service::Places::Create.new(geo_json: struct_retrieve.data).call

          # puts struct_retrieve.data

          # struct_retrieve.data
        end

      end
    end
  end
end
