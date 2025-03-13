# frozen_string_literal: true

module Service
  module Places
    class CreateFromManual

      def initialize(name:, city:)
        @name = name
        @city = city
      end

      def call
        geo_json = {
          "type"=>"FeatureCollection",
          "features" => [
            {
              "type" => "Feature",
              "geometry" => {
                "coordinates"=>[0.0, 0.0],
                "type"=>"Point",
              },
              "properties" => {
                "id" => ULID.generate,
                "name" => @name,
                "coordinates" => {
                  "latitude"=>0.0,
                  "longitude"=>0.0,
                },
              }
            }
          ]
        }
            
        ::Service::Places::Create.new(
          city: @city,
          geo_json: geo_json,
          source_name: ::Model::Place::SOURCE_MANUAL,
        ).call
      end

    end
  end
end