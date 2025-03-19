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

      def self.brands_set_by_tags(tags:)
        if tags.length == 0
          brands_set_all
        else
          # return brands filtered by places with matching tags
          Model::Place.tagged_with_any(tags).select(:brands).all().filter{ |p| p.brands.length > 0 }.inject(Set[]) { |s, o| s.merge(o.brands) }
        end
      end

      def self.brands_set_by_box(box:, tags: [])
        # return brands based on city or region box object
        if box.is_a?(::Model::City)
          return brands_set_by_city_name(city_name: box.name, tags: tags)
        else
          return brands_set_by_region(region: box, tags: tags)
        end
      end

      def self.brands_set_by_region(region:, tags: [])
        # find places by region bounding box and optional tags list
        query = Model::Place.where(
          Sequel.lit("ST_SetSRID(ST_MakePoint(lon, lat), 4326) && ST_SetSRID(ST_MakeBox2D(ST_Point(#{region.lon_min}, #{region.lat_min}), ST_Point(#{region.lon_max}, #{region.lat_max})), 4326)")
        )
        
        if tags.length > 0
          query = query.tagged_with_any(tags)
        end

        query.select(:brands).all().inject(Set[]) { |s, o| s.merge(o.brands) }
      end

      def self.brands_set_by_city_name(city_name:, tags: [])
        query = Model::Place.where(city: city_name)

        if tags.length > 0
          query = query.tagged_with_any(tags)
        end

        query.select(:brands).all().inject(Set[]) { |s, o| s.merge(o.brands) }
      end

    end
  end
end
