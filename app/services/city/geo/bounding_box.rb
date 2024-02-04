# frozen_string_literal: true

module Service
  module City
    module Geo

      def self.bounding_box(city:, radius:)
        Geocoder::Calculations.bounding_box([city.lon, city.lat], radius, {units: :mi})
      end

    end
  end
end
