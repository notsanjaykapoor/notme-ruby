# frozen_string_literal: true

module Service
  module Geo
    class Geocode
      #
      # Use the geocoder service to search by name and return the geocoded place.
      #

      def initialize(name:, type:)
        @name = name.to_s
        @type = type.to_s

        @address_types = {
          "country" => 1,
          "continent" => 2,
        }
        @struct = Struct.new(:code, :features, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        Console.logger.info(self, "#{Thread.current[:rid]} name '#{@name}', type '#{@type}'")

        geocode_results = Geocoder.search(@name)

        if geocode_results.length == 0
          struct.code = 404
          return struct
        end

        geocode_class = geocode_results[0].class.to_s

        if geocode_class == "Geocoder::Result::Geoapify"
          struct.features = _results_filter_geoapify(geocode_results: geocode_results)
        elsif geocode_class == "Geocoder::Result::Nominatim"
          struct.features = _results_filter_nominatim(geocode_results: geocode_results)
        end

        struct
      end

      def _results_filter_geoapify(geocode_results:)
        #
        # Filter geocode_results array based on result_type and map results set to a list of geojson features.
        #

        if @type == "city"
          result_types = {
            "city" => 1,
            "county" => 2,
          }
          name_key = "city"
        elsif @type == "region"
          result_types = {
            "country" => 1,
          }
          name_key = "country"
        end

        results = geocode_results.select do |o|
          o.data.fetch("type") == "Feature" and result_types.keys.include?(o.data.dig("properties", "result_type"))
        end

        features = results.map do |o|
          # data object is already in geojson format
          o.data.tap do |h|
            h["properties"]["name"] = h.dig("properties", name_key)
          end
        end

        features
      end

      def _results_filter_nominatim(geocode_results:)
        #
        # Filter geocode_results array based on result_type and map results set to a list of geojson features.
        #

        if @type == "city"
          address_types = {
            "city" => 1,
            "province" => 2,
          }
        elsif @type == "region"
          address_types = {
            "country" => 1,
            "continent" => 2,
          }
        end

        results = geocode_results.select do |o|
          address_types.keys.include?(o.data.fetch("addresstype"))
        end

        features = results.map do |o|
          # create geojson object
          addr = o.data.fetch("address")
          props = o.data.tap do |h|
            h["country"] = addr.fetch("country")
            h["country_code"] = addr.fetch("country_code")
          end
          
          {
            "type" => "Feature",
            "bbox" => o.data.fetch("boundingbox"),
            "geometry" => {
              "type" => "Point",
              "coordinates" => [o.data.fetch("lon"), o.data.fetch("lat")],
            },
            "properties" => props,
          }
        end

        features
      end
 
    end
  end
end