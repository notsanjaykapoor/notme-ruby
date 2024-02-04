# frozen_string_literal: true

module Service
  module Places
    class Create

      def initialize(geo_json:)
        @geo_json = geo_json

        @type = @geo_json.dig("type")

        @struct = Struct.new(:code, :places, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        if @type == "FeatureCollection"
          struct.places = @geo_json.dig("features").map { |feature| _feature_parse(feature: feature)}

          for place in struct.places
            place.save
          end
        end

        struct
      end

      def _feature_parse(feature:)
        # assert feature.dig("type") == "Feature"

        props = feature.dig("properties")

        city = props.dig("context").dig("place").dig("name")
        country_code = props.dig("context").dig("country").dig("country_code")
        lat = props.dig("coordinates").dig("latitude")
        lon = props.dig("coordinates").dig("longitude")
        mapbox_id = props.dig("mapbox_id")
        name = props.dig("name")

        ::Model::Place.new(
          city: city,
          country_code: country_code,
          data: {},
          geo_json: feature,
          lat: lat,
          lon: lon,
          name: name,
          source_id: mapbox_id,
          source_name: "mapbox",
          tags: [],
          updated_at: Time.now.utc,
        )
      end

    end
  end
end