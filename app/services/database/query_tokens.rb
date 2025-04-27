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

        query = @query.gsub(/:\s+/, ":")

        tokens_list = query.to_s.split(" ")
        tokens_count = tokens_list.length
        tokens_i = 0

        while tokens_i < tokens_count
          token = tokens_list[tokens_i]

          if token.empty? or !token.include?(":")
            # skip, looking for next token
            tokens_i += 1
            continue
          end

          field, value = token.split(":")

          while tokens_i+1 < tokens_count
            # greedy parse value until we find next field
            token_j = tokens_list[tokens_i+1]
            if token_j.include?(":")
              # found next field
              break
            end

            # append this token to current token value
            value = "#{value} #{token_j}"
            tokens_i += 1
          end

          value_norm = value.strip()

          struct.tokens.push({
            field: field,
            value: value_norm,
          })

          tokens_i += 1
        end

        struct
      end

    end
  end
end
