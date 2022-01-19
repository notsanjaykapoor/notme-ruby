# frozen_string_literal: true

module Services
  module Terminal
    class ParseObject

      def initialize(object:)
        @object = object

        @struct = Struct.new(:code, :tokens, :message)
      end

      def call
        struct = @struct.new(0, [], nil)

        cmd = @object[:cmd]

        if cmd.nil?
          struct.code = 422
          struct.message = "cmd missing"
        else
          struct.tokens = cmd.split(/[^a-zA-Z0-9_\.]+/) # \W + period
        end

        struct
      end

    end
  end
end
