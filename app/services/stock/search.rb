# frozen_string_literal: true

module Service
  module Stock
    class Search

      def initialize(query:, offset:, limit:)
        @query = query
        @offset = offset
        @limit = limit

        @struct = Struct.new(:code, :stocks, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        Console.logger.info(self, "#{Thread.current[:rid]} query #{@query}")

        begin
          struct_tokens = ::Service::Database::QueryTokens.new(
            query: @query
          ).call

          tokens = struct_tokens.tokens
          query = ::Model::Stock

          tokens.each do |object|
            field = object[:field]
            value = object[:value]

          end

          if ["category"].include?(field)
            if value[/^~/]
              # todo
            else
              value = value.downcase
              query = query.tagged_with_any("category:#{value}")
            end
          elsif ["industry"].include?(field)
            if value[/^~/]
              # todo
            else
              value = value.downcase
              query = query.tagged_with_any("industry:#{value}")
            end
          elsif ["price"].include?(field)
            query = query.where(field: value)
          elsif ["price_gte"].include?(field)
            query = query.price_gte(value)
          elsif ["price_lte"].include?(field)
            query = query.price_lte(value)
          elsif ["ticker"].include?(field)
            if value[/^~/]
              value = value.gsub(/~/, '')
              query = query.ticker_like(value)
            else
              query = query.ticker_eq(value)
            end
          end

          query = query.order(Sequel.asc(:ticker)).offset(@offset).limit(@limit)

          struct.stocks = query.select(:price, :tags, :ticker).map do |object|
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

    end
  end
end
