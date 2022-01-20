# frozen_string_literal: true

module GqlService
  module Cities
    class List

      def initialize(query:, offset:, limit:)
        @query = query
        @offset = offset
        @limit = limit

        @fields = {
          "city" => {
            "name" => "name",
            "temp" => "temp",
            "temp_gte" => "temp_gte",
            "temp_lte" => "temp_lte",
          }
        }

        @struct = Struct.new(:code, :cities, :errors)
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
            query: City,
            tokens: tokens,
          )

          sequel_query = sequel_query.order(Sequel.asc(:name)).offset(@offset).limit(@limit)

          struct.cities = sequel_query.map do |object|
            {
              feels_like: object.feels_like,
              lat: object.lat,
              lon: object.lon,
              name: object.name,
              region: object.region,
              tags: object.tags,
              temp: object.temp,
              temp_max: object.temp_max,
              temp_min: object.temp_min,
              updated_at_unix: object.updated_at_unix,
              weather: object.weather,
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

          if [klass, field_] == ["city", "name"]
            if value[/^~/]
              value = value.gsub(/~/, '')
              query = query.name_like(value)
            else
              value = value.gsub(/-/, " ").split(" ").map{ |s| s.capitalize }.join(" ")
              query = query.name_eq(value)
            end
          elsif [klass, field_] == ["city", "temp"]
            query = query.where(price: value)
          elsif [klass, field_] == ["city", "temp_gte"]
            query = query.price_gte(value)
          elsif [klass, field_] == ["city", "temp_lte"]
            query = query.price_lte(value)
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
