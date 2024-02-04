# frozen_string_literal: true

module Service
  module City
    class Search

      def initialize(query:, offset:, limit:)
        @query = query
        @offset = offset
        @limit = limit

        @struct = Struct.new(:code, :cities, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        Console.logger.info(self, "#{Thread.current[:rid]} query #{@query}")

        begin
          struct_tokens = ::Service::Database::QueryTokens.new(
            query: @query
          ).call

          tokens = struct_tokens.tokens
          query = ::Model::City

          tokens.each do |object|
            field = object[:field]
            value = object[:value]

            if ["name"].include?(field)
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("#{field} ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.capitalize }.join(" ")
                query = query.where(field: value)
              end
            elsif ["temp"].include?(field)
              query = query.where(temp: value)
            elsif ["temp_gte"].include?(field)
              query = query.where(Sequel.lit("temp >= ?", value.to_f))
            elsif ["temp_lte"].include?(field)
              query = query.where(Sequel.lit("temp <= ?", value.to_f))
            end
          end

          query = query.order(Sequel.asc(:name)).offset(@offset).limit(@limit)

          struct.cities = query.map do |object|
            {
              feels_like: object.feels_like,
              id: object.id,
              lat: object.lat,
              lon: object.lon,
              name: object.name,
              region: object.region,
              seconds_ago: Time.now.utc.to_i - object.updated_at_unix,
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

    end
  end
end
