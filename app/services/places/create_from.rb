# frozen_string_literal: true

module Service
  module Places
    class CreateFrom

      def initialize(mapbox_id:)
        @mapbox_id = mapbox_id

        @struct = Struct.new(:code, :places, :errors)
      end

      def call
        retrieve_results = ::Service::Mapbox::Retrieve.new(id: @mapbox_id).call

        if retrieve_results.code != 0
          struct = @struct.new(retrieve_results.code, [], retrieve_results.errors)
          return struct
        end

        ::Service::Places::Create.new(geo_json: retrieve_results.data).call
      end

    end
  end
end