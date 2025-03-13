# frozen_string_literal: true

module Service
  module City
    class Search

      def initialize(query:, offset:, limit:)
        #
        # Search database for city(s) in query
        #
        @query = query
        @offset = offset
        @limit = limit

        @struct = Struct.new(:code, :cities, :total, :errors)
      end

      def call
        struct = @struct.new(0, [], 0, [])

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

            if ["id"].include?(field)
              query = query.where(id: value)
            elsif ["name"].include?(field)
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("#{field} ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.downcase }.join(" ")
                query = query.where(Sequel.lit("lower(name) like ?", "#{value}%"))
              end
            elsif ["temp"].include?(field)
              query = query.where(temp: value)
            elsif ["temp_gte"].include?(field)
              query = query.where(Sequel.lit("temp >= ?", value.to_f))
            elsif ["temp_lte"].include?(field)
              query = query.where(Sequel.lit("temp <= ?", value.to_f))
            end
          end

          struct.total = query.count

          query = query.order(Sequel.asc(:name)).offset(@offset).limit(@limit)

          # struct.cities = query.select(:bbox, :country_code, :data, :id, :lat, :lon, :name, :source_id, :source_name).all
          struct.cities = query.all
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
