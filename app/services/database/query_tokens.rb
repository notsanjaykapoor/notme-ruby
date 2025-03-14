# frozen_string_literal: true

module Service
  module Database
    class QueryTokens

      HYPHEN_REPLACE_CHAR = " "
      PLUS_REPLACE_CHAR = " "

      def initialize(query:)
        @query = query.to_s
      end

      def call
        struct = Struct.new(:tokens, :code, :errors).new([], 0, [])

        # normalize query, remove extra spaces

        @query = @query.gsub(/:\s+/, ":")

        # split query into tokens

        @query.to_s.split(" ").each do |token|
          field, value = token.split(":")

          if field.nil? || value.nil?
            # skip
            next
          end

          # replace [-, +] chars with spaces
          value = value.gsub(/-/, HYPHEN_REPLACE_CHAR).gsub(/\+/, PLUS_REPLACE_CHAR)

          struct.tokens.push({
            field: field,
            value: value,
          })
        end

        struct
      end

    end
  end
end
