# frozen_string_literal: true

module Api
  module V1
    module Queue
      class Add

        def initialize(request:, response:)
          @request = request
          @response = response

          @params = @request.params
          @value = @params["value"].to_s

          @response.status = 200
        end

        def call
          Console.logger.info(self, "value #{@value}")

          ::Services::Queue::Producer.new(
            queue: MessageQueue.instance,
            object: @value,
          ).call

          {
            code: 0,
            value: @value,
          }
        end

      end
    end
  end
end
