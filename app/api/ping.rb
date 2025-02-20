# frozen_string_literal: true

module Api
  class Ping

    def initialize(request:, response:)
      @request = request
      @response = response

      @params = @request.params

      @response.status = 200
    end

    def call
      code = @params.fetch("code", 0)
      message = @params.fetch("message", "pong")

      {
        code: code,
        message: message,
      }
    end

  end
end
