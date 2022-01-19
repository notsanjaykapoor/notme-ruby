# frozen_string_literal: true

module Services
  module Terminal
    class Parse

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

            struct_parse_object = ::Services::Terminal::ParseObject.new(
              object: object
            ).call

            if struct_parse_object.code.nonzero?
              result = {
                code: struct_parse_object.code,
                message: struct_parse_object.message,
              }
            else
              struct_parse_tokens = ::Services::Terminal::ParseTokens.new(
                tokens: struct_parse_object.tokens
              ).call

              cmd = struct_parse_tokens.cmd

              if struct_parse_tokens.code.nonzero?
                result = {
                  code: struct_parse_tokens.code,
                  message: struct_parse_tokens.message,
                }
              elsif cmd == "help"
                result = ::Services::Terminal::ParseCmdHelp.new(
                  tokens: struct_parse_tokens.tokens
                ).call
              else
                result = ::Services::Terminal::ParseCmdTicker.new(
                  ticker: struct_parse_tokens.ticker,
                  op: struct_parse_tokens.op,
                  tokens: struct_parse_tokens.tokens,
                ).call
              end
            end

            Console.logger.info(self, "output: #{result.to_h}")

            @output_queue.enqueue(result.to_h)
          end
        end

        struct
      end

    end
  end
end
