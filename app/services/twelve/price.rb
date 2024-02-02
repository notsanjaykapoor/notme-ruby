# frozen_string_literal: true

module Service
  module Twelve
    class Price

      def initialize(symbols:)
        @symbols = symbols

        @api_key = ENV["TWELVE_API_KEY"]
        @endpoint = "https://api.twelvedata.com/price"
        @format = "json"
        @http = ::Service::Twelve::Http.instance

        @struct = Struct.new(:code, :data, :errors)
      end

      def call
        struct = @struct.new(0, {}, [])

        Console.logger.info(self, "#{Thread.current[:rid]} #{@symbols}")

        begin
          params = {
            apikey: @api_key,
            format: @format,
            symbol: @symbols.join(","),
          }

          response = @http.get(@endpoint, params: params)

          if response.code != 200
            struct.code = response.code

            return struct
          end

          response_json = JSON.parse(response.body)

          # normalize response format
          if response_json.keys.include?("price")
            struct.data[@symbols[0]] = response_json
          else
            struct.data = response_json
          end
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
  