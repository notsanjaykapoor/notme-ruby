# frozen_string_literal: true

module Service
  module Places
    class Create

      def initialize(city:, geo_json:, source_name:)
        @city = city
        @geo_json = geo_json
        @source_name = source_name

        @type = @geo_json.dig("type")

        @struct = Struct.new(:code, :places, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        if @type == "FeatureCollection"
          places = @geo_json.dig("features").map { |feature| _feature_parse(feature: feature)}

          for place in places
            if not place
              struct.code = 422
              return struct
            end

            place.save
            struct.places.append(place)
          end
        else
          struct.code = 422
        end

        struct
      end

      def _feature_parse(feature:)
        # assert feature.dig("type") == "Feature"

        if feature.dig("type") != "Feature"
          return nil
        end

        props = feature.dig("properties")

        lat = props.dig("coordinates").dig("latitude")
        lon = props.dig("coordinates").dig("longitude")
        source_id = props.dig("mapbox_id") || props.dig("id")
        name = props.dig("name")
        tags = _feature_parse_tags(categories: props.dig("poi_category") || [])

        ::Model::Place.new(
          city: @city.name,
          country_code: @city.country_code,
          data: {},
          geo_json: feature,
          lat: lat,
          lon: lon,
          name: name,
          source_id: source_id,
          source_name: @source_name,
          tags: tags,
          updated_at: Time.now.utc,
        )
      end

      def _feature_parse_tags(categories:)
        tags = Set[]

        for s in categories
          s_ = s.downcase

          if s_.include?("food")
            tags.add("food")
          end

          if s_.include?("bar") or s_.include?("drink")
            tags.add("bar")
          end

          if s_.include?("hotel")
            tags.add("hotel")
          end

          if s_.include?("clothing") or s_.include?("shopping")
            tags.add("fashion")
          end
        end

        tags.to_a.sort
      end

    end
  end
end