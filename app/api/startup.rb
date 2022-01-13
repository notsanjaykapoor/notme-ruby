# frozen_string_literal: true

module Api
  class Startup

    def initialize(request:, response:)
      @request = request
      @response = response

      @params = @request.params

      @response.status = 200
    end

    def call
      code = @params.fetch("code", 0)

      Console.logger.info(self)

      {
        code: code,
      }
    end

  end
end
