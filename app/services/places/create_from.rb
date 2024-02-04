# frozen_string_literal: true

module Service
  module Places
    class CreateFrom

      def initialize(mapbox_id:)
        @mapbox_id = mapbox_id
      end

      def call
        retrieve_results = ::Service::Mapbox::Retrieve.new(id: @mapbox_id).call

        ::Service::Places::Create.new(geo_json: retrieve_results.data).call
      end

    end
  end
end