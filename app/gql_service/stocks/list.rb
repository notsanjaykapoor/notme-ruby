# frozen_string_literal: true

module GqlService
  module Stocks
    class List

      def initialize(query:, offset:, limit:)
        @query = query
        @offset = offset
        @limit = limit

        @fields = {
          "stock" => {
            "category" => "category",
            "industry" => "industry",
            "price" => "price",
            "price_gte" => "price_gte",
            "price_lte" => "price_lte",
            "ticker" => "ticker",
          }
        }

        @struct = Struct.new(:code, :stocks, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        Console.logger.info(self, "#{Thread.current[:rid]} query #{@query}")

        begin
          struct_tokens = ::Services::Database::QueryTokens.new(
            query: @query
          ).call

          tokens = struct_tokens.tokens

          sequel_query = _query_filter(
            query: Stock,
            tokens: tokens,
          )

          sequel_query = sequel_query.order(Sequel.asc(:ticker)).offset(@offset).limit(@limit)

          struct.stocks = sequel_query.select(:price, :tags, :ticker).map do |object|
            {
              price: object.price,
              tags: object.tags,
              ticker: object.ticker,
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

          if [klass, field_] == ["stock", "category"]
            if value[/^~/]
              # todo
            else
              value = value.downcase
              query = query.tagged_with_any("category:#{value}")
            end
          elsif [klass, field_] == ["stock", "industry"]
            if value[/^~/]
              # todo
            else
              value = value.downcase
              query = query.tagged_with_any("industry:#{value}")
            end
          elsif [klass, field_] == ["stock", "price"]
            query = query.where(price: value)
          elsif [klass, field_] == ["stock", "price_gte"]
            query = query.price_gte(value)
          elsif [klass, field_] == ["stock", "price_lte"]
            query = query.price_lte(value)
          elsif [klass, field_] == ["stock", "ticker"]
            if value[/^~/]
              value = value.gsub(/~/, '')
              query = query.ticker_like(value)
            else
              query = query.ticker_eq(value)
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
