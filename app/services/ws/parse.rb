# frozen_string_literal: true

require "json"
require "protocol/websocket/json_message"

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
          while json_message = @input_queue.dequeue
            Console.logger.info(self, "input: #{json_message.to_str}")

            message = JSON.parse(json_message.to_str)
            topic = message["topic"]

            if topic[/^ping/]
              result = {
                code: 0,
                message: "pong",
                topic: topic,
              }
            elsif topic[/^weather/]
              struct_weather = ::Services::Weather::Terminal::Parse.new(
                cmd: topic
              ).call

              result = {
                code: struct_weather.code,
                message: struct_weather.message,
                topic: topic,
              }
            else
              result = {
                code: 422,
                message: "invalid",
                topic: topic,
              }
            end

            Console.logger.info(self, "output: #{result.to_h}")

            json_result = Protocol::WebSocket::JSONMessage.generate(result)
            @output_queue.enqueue(json_result)
          end
        end

        struct
      end

    end
  end
end
