# frozen_string_literal: true

module Boot
  class Database

    def initialize
      @struct = Struct.new(:code, :connection, :errors)
    end

    def call
      struct = @struct.new(0, nil, [])

      Console.logger.info(self, "")

      struct.connection = ::Sequel.connect(ENV["DATABASE_URL"])

      struct
    end

  end
end
