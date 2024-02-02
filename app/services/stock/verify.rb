# frozen_string_literal: true

require "debug"

module Service
  module Stock
    class Verify

      def initialize(symbol:)
        @symbol = symbol
      end

      def call
        Console.logger.info(self, "#{Thread.current[:rid]} symbol #{@symbol}")

        struct_price = ::Service::Twelve::Price.new(symbols: [@symbol]).call

        if struct_price.code != 0
          return struct_price.code
        end
        
        if not struct_price.data.dig(@symbol.to_s, "price")
          return 1
        end

        0
      end

    end
  end
end

        