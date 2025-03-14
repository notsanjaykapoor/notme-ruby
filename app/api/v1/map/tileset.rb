# frozen_string_literal: true

module Api
  module V1
    module Map
      class Tileset

        def initialize(request:, response:, box:)
          @request = request
          @response = response
          @box = box

          @params = @request.params
          @query = @params["q"].to_s

          @response.status = 200
        end

        def call
          if @box
            search_results = ::Service::Places::Search.new(
              query: @query,
              box: @box,
              offset: 0,
              limit: 100,
            ).call

            features = search_results.places.map do |place|
              place.geo_json_compact(color: ::Service::Places::Tags.tag_color(tags: place.tags))
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
