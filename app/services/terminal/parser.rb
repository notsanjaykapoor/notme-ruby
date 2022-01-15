# frozen_string_literal: true

module Services
  module Terminal
    class Parser

      def initialize(input_queue:, output_queue:)
        @input_queue = input_queue
        @output_queue = output_queue

        @struct = Struct.new(:code, :errors)
      end

      def call
        struct = @struct.new(0, [])

        Async do
          while object = @input_queue.dequeue
            Console.logger.info(self, "input: #{object}")

            result = _parse_cmd(
              object: object
            )

            Console.logger.info(self, "output: #{result}")

            @output_queue.enqueue(result)
          end
        end

        struct
      end

      protected

      def _error_cmd_invalid
        {
          code: 422,
          message: "invalid cmd",
        }
      end

      def _error_op_missing
        {
          code: 422,
          message: "missing op",
        }
      end

      def _error_stock_exists
        {
          code: 409,
          message: "stock exists",
        }
      end

      def _error_stock_not_found
        {
          code: 404,
          message: "invalid stock",
        }
      end

      def _parse_cmd(object:)
        tokens = _parse_tokens(
          object: object
        )

        if tokens.nil?
          return _error_cmd_invalid
        end

        cmd = tokens.shift

        if ["stock", "ticker"].include?(cmd)
          return _parse_cmd_ticker(
            tokens: tokens
          )
        else
          return _error_cmd_invalid
        end
      end

      def _parse_cmd_ticker(tokens:)
        ticker = tokens.shift.to_s.upcase

        if ticker.nil?
          return _error_not_found
        end

        ticker = ticker.upcase
        stock = Stock.first(ticker: ticker)

        op = tokens.shift

        if op.nil?
          return _error_op_missing
        end

        op = op.downcase

        if op == "create"
          if stock.present?
            return _error_stock_exists
          end

          cmd = tokens.shift

          if cmd.nil?
            return _error_cmd_invalid
          end

          if cmd == "price"
            price = tokens.shift.to_f
            stock = Stock.create(ticker: ticker, price: price)

            message = "ticker created"
          else
            return _error_cmd_invalid
          end
        elsif op == "delete"
          if stock.blank?
            return _error_stock_not_found
          end

          stock.delete

          message = "ticker deleted"
        elsif op == "update"
          if stock.blank?
            return _error_stock_not_found
          end

          cmd = tokens.shift

          if cmd.nil?
            return _error_cmd_invalid
          end

          if cmd == "price"
            price = tokens.shift.to_f

            stock = Stock.first(ticker: ticker)
            stock.update(price: price)

            message = "ticker updated"
          else
            return _error_cmd_invalid
          end
        else
          return _error_cmd_invalid
        end

        {
          code: 0,
          message: message || "",
        }
      end

      def _parse_tokens(object:)
        cmd = object[:cmd]

        if cmd.nil?
          return cmd
        end

        cmd.split(/[^a-zA-Z0-9_\.]+/) # \W + period
      end

    end
  end
end
