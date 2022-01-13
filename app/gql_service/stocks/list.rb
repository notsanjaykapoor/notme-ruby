# frozen_string_literal: true

module GqlService
  module Stocks
    class List

      def initialize(query:)
        @query = query

        @topic = self.class.name.underscore

        @fields = {
          "stock" => {
            "name" => "name",
            "price" => "price",
          }
        }

        @struct = Struct.new(:code, :stocks, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        Console.logger.info(self, "query #{@query}")

        begin
          struct_tokens = ::Services::Database::QueryTokens.new(
            query: @query
          ).call

          tokens = struct_tokens.tokens

          sequel_query = _query_filter(
            query: Stock,
            tokens: tokens,
          )

          sequel_query = sequel_query.order(Sequel.asc(:name))

          struct.stocks = sequel_query.select(:name, :price).map do |object|
            {
              name: object[:name],
              price: object[:price],
            }
          end
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)

          Console.logger.failure(self, e)
        end

        struct
      end

      protected

      def _query_filter(query:, tokens:)
        tokens.each do |object|
          field = object[:field]
          value = object[:value]

          # map field to kalss and field tuple

          klass, field_ = _query_map(
            field: field
          )

          if klass.nil? || field.nil?
            raise "invalid field:#{field}"
          end

          if [klass, field_] == ["stock", "name"]
            if value[/^~/]
              value = value.gsub(/~/, '')
              query = query.name_like(value)
            else
              query = query.name_eq(value)
            end
          elsif [klass, field_] == ["stock", "price"]
            if value[/^>/]
              value = value.gsub(/>/, '')
              query = query.price_gte(value)
            elsif value[/^</]
              value = value.gsub(/</, '')
              query = query.price_lte(value)
            end
          end
        end

        query
      end

      def _query_map(field:)
        @fields.each_pair do |klass, mapping|
          if mapping.has_key?(field)
            return [klass, mapping[field]]
          end
        end

        return [nil, nil]
      end

    end
  end
end
