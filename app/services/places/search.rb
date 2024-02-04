# frozen_string_literal: true

module Service
  module Places
    class Search

      def initialize(query:, offset:, limit:)
        @query = query
        @offset = offset
        @limit = limit

        @struct = Struct.new(:code, :places, :errors)
      end

      def call
        struct = @struct.new(0, [], [])

        Console.logger.info(self, "#{Thread.current[:rid]} query #{@query}")

        begin
          struct_tokens = ::Service::Database::QueryTokens.new(
            query: @query
          ).call

          tokens = struct_tokens.tokens
          query = ::Model::Place

          tokens.each do |object|
            field = object[:field]
            value = object[:value]

            if ["city"].include?(field)
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("#{field} ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.capitalize }.join(" ")
                query = query.where(field: value)
              end
            elsif ["name"].include?(field)
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("#{field} ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.capitalize }.join(" ")
                query = query.where(field: value)
              end
            end
          end

          struct.places = query.order(Sequel.asc(:name)).offset(@offset).limit(@limit).all
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
