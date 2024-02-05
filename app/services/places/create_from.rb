# frozen_string_literal: true

module Service
  module Places
    class CreateFrom

      def initialize(mapbox_id:, mapbox_session:)
        @mapbox_id = mapbox_id
        @mapbox_session = mapbox_session
      end

      def call
        retrieve_results = ::Service::Mapbox::Retrieve.new(id: @mapbox_id, session: @mapbox_session).call

        if retrieve_results.code != 0
          return retrieve_results
        end

        ::Service::Places::Create.new(geo_json: retrieve_results.data).call
      end

    end
  end
end