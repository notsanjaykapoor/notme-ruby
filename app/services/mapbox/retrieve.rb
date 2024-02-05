# frozen_string_literal: true

# docs: https://docs.mapbox.com/api/search/search-box/

module Service
  module Mapbox
    class Retrieve

      def initialize(id:, session:)
        @id = id # mapbox id

        @token = ENV["MAPBOX_TOKEN"]
        @endpoint = "https://api.mapbox.com/search/searchbox/v1/retrieve/#{@id}"
        @session_token = session
        @http = ::Service::Mapbox::Http.instance

        @struct = Struct.new(:code, :data, :errors)
      end

      def call
        struct = @struct.new(0, {}, [])

        Console.logger.info(self, "#{Thread.current[:rid]} id '#{@id}'")

        begin
          params = {
            access_token: @token, # required
            session_token: @session_token, # required
          }

          response = @http.get(@endpoint, params: params)

          if response.code != 200
            struct.code = response.code

            return struct
          end

          struct.data = JSON.parse(response.body)
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
    