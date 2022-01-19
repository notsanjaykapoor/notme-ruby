# frozen_string_literal: true

module Services
  module Terminal
    class ParseCmdHelp

      def initialize(tokens:)
        @tokens = tokens

        @struct = Struct.new(:code, :message)
      end

      def call
        struct = @struct.new(
          400,
          "ticker :ticker create|delete|update"
        )

        struct
      end

    end
  end
end
