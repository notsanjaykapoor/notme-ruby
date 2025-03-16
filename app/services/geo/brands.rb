# frozen_string_literal: true

module Service
  module Geo
    class Brands

      def self.brands_flag(tags:)
        # returns 1 if brands are related to the tags list, 0 otherwise
        if tags.to_set.intersect?(["fashion", "shoes"].to_set)
          1
        else
          0
        end
      end

      def self.brands_set_all
        Model::Place.select(:brands).all().inject(Set[]) { |s, o| s.merge(o.brands) }
      end

      def self.brands_set_by_box(box:)
        # return brands based on city or region box object
        if box.is_a?(::Model::City)
          return brands_set_by_city_name(city_name: box.name)
        else
          return brands_set_by_region(region: box)
        end
      end

      def self.brands_set_by_region(region:)
        # find places by region bounding box
        Model::Place.where(
          Sequel.lit("ST_SetSRID(ST_MakePoint(lon, lat), 4326) && ST_SetSRID(ST_MakeBox2D(ST_Point(#{region.lon_min}, #{region.lat_min}), ST_Point(#{region.lon_max}, #{region.lat_max})), 4326)")
        ).select(:brands).all().inject(Set[]) { |s, o| s.merge(o.brands) }
      end

      def self.brands_set_by_city_name(city_name:)
        Model::Place.where(city: city_name).select(:brands).all().inject(Set[]) { |s, o| s.merge(o.brands) }
      end

    end
  end
end
