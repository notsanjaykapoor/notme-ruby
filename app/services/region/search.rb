# frozen_string_literal: true

module Service
  module Region
    class Search

      def initialize(query:, offset:, limit:)
        #
        # Search database for city(s) in query
        #
        @query = query
        @offset = offset
        @limit = limit

        @struct = Struct.new(:code, :regions, :total, :errors)
      end

      def call
        struct = @struct.new(0, [], 0, [])

        Console.logger.info(self, "#{Thread.current[:rid]} query #{@query}")

        begin
          struct_tokens = ::Service::Database::QueryTokens.new(
            query: @query
          ).call

          tokens = struct_tokens.tokens
          query = ::Model::Region

          tokens.each do |object|
            field = object[:field]
            value = object[:value]

            if ["code"].include?(field)
              query = query.where(code: value.upcase)
            elsif ["id"].include?(field)
              query = query.where(id: value)
            elsif ["name"].include?(field)
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("#{field} ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.downcase }.join(" ")
                query = query.where(Sequel.lit("lower(name) like ?", "#{value}%"))
              end
            end
          end

          struct.total = query.count

          query = query.order(Sequel.asc(:name)).offset(@offset).limit(@limit)

          struct.regions = query.all
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
