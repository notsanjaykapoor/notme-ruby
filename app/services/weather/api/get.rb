# frozen_string_literal: true

module Services
  module Weather
    module Api
      class Get

        def initialize(query:)
          @query = query

          @mode = "json"
          @units = "imperial"
          @appid = ENV["OPENWEATHER_API_TOKEN"]

          @http = ::Services::Weather::Api::Http.instance
          @endpoint = "https://api.openweathermap.org/data/2.5/weather"
          @struct = Struct.new(:code, :data, :errors)
        end

        #
        # docs: https://openweathermap.org/current
        #

        def call
          struct = @struct.new(0, nil, [])

          begin
            params = {
              appid: @appid,
              mode: @mode,
              q: @query,
              units: @units,
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
end
