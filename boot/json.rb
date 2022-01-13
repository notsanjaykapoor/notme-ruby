# frozen_string_literal: true

module Boot
  class Json

    def initialize
      @struct = Struct.new(:code, :errors)
    end

    def call
      struct = @struct.new(0, [])

      Console.logger.info(self, "")

      Oj.default_options = {
        mode: :compat
      }

      struct
    end

  end
end
