# frozen_string_literal: true

module Services
  module Ws
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

            cmd = object[:cmd].to_s.downcase

            if cmd[/^weather/]

              struct_weather = ::Services::Weather::Terminal::Parse.new(
                cmd: cmd
              ).call

              result = {
                code: struct_weather.code,
                message: struct_weather.message,
              }
            else
              result = {
                code: 500,
                message: "invalid cmd",
              }
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
