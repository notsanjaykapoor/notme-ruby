# frozen_string_literal: true

module Services
  module Terminal
    class ParseCmdTicker

      def initialize(ticker:, op:, tokens:)
        @ticker = ticker
        @op = op
        @tokens = tokens

        @stock = Stock.first(ticker: @ticker)

        @struct = Struct.new(:code, :message)
      end

      def call
        case @op
        in 'create'
          result = _ticker_create
        in 'delete'
          result = _ticker_delete
        in 'update'
          result = _ticker_update
        end

        result
      end

      protected

      def _ticker_create
        struct = @struct.new(0, nil)

        if @stock.present?
          struct.code = 409
          struct.message = "ticker exists"

          return struct
        end

        case @tokens
        in [/price/i, String => price]
          stock = Stock.create(ticker: @ticker, price: price)

          message = "ticker created"
        else
          struct.code = 422
          struct.message = "ticker #{@ticker} create price :price"

          return struct
        end

        struct
      end

      def _ticker_delete
        struct = @struct.new(0, nil)

        if @stock.nil?
          struct.code = 404
          struct.message = "ticker not found"

          return struct
        end

        if @tokens.size.nonzero?
          struct.code = 422
          struct.message = "ticker #{@ticker} delete"

          return struct
        end

        @stock.delete

        struct.message = "ticker deleted"

        struct
      end

      def _ticker_update
        struct = @struct.new(0, nil)

        if @stock.nil?
          struct.code = 404
          struct.message = "ticker not found"

          return struct
        end

        case @tokens
        in [/price/i, String => price]
          stock.update(price: price)

          message = "ticker updated"
        else
          struct.code = 422
          struct.message = "ticker #{@ticker} update price :price"

          return struct
        end

        struct
      end

    end
  end
end
