# frozen_string_literal: true

module Service
  module Places
    class CreateFromAddress

      def initialize(name:, street:, city:, postal:)
        @name = name
        @street = street
        @city = city
        @postal = postal
      end

      def call
        forward_results = ::Service::Mapbox::GeoForward.new(street: @street, city: @city).call

        if forward_results.code != 0
          return forward_results.code
        end

        data = forward_results.data.tap do |o|
          # get data collection and pick first feature, since we are creating a single place
          o["features"] = o.fetch("features")[0..0]

          # update feature
          o.fetch("features")[0]["properties"]["name"] = @name
          o.fetch("features")[0]["geometry"]["coordinates"] = [@lon, @lat]

          # since this isn't a real mapbox object, don't use the mapbox id
          o.fetch("features")[0]["properties"]["mapbox_id"] = ULID.generate
        end

        # create place object
        ::Service::Places::Create.new(geo_json: data, source_name: ::Model::Place::SOURCE_MANUAL).call
      end

    end
  end
end