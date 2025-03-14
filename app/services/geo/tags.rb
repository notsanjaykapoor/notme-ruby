# frozen_string_literal: true

module Service
  module Geo
    class Tags

      def self.tags_set_all
        Model::Place.select(:tags).all().inject(Set[]) { |s, o| s.merge(o.tags) }
      end

      def self.tags_set_by_box(box:)
        # return tags based on city or region box object
        if box.is_a?(::Model::City)
          return tags_set_by_city_name(city_name: box.name)
        else
          return tags_set_by_region(region: box)
        end
      end

      def self.tags_set_by_region(region:)
        # find places by region bounding box
        Model::Place.where(
          Sequel.lit("ST_SetSRID(ST_MakePoint(lon, lat), 4326) && ST_SetSRID(ST_MakeBox2D(ST_Point(#{region.lon_min}, #{region.lat_min}), ST_Point(#{region.lon_max}, #{region.lat_max})), 4326)")
        ).select(:tags).all().inject(Set[]) { |s, o| s.merge(o.tags) }
      end

      def self.tags_set_by_city_name(city_name:)
        Model::Place.where(city: city_name).select(:tags).all().inject(Set[]) { |s, o| s.merge(o.tags) }
      end

    end
  end
end
