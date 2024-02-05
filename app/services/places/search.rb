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

            if ["city"].include?(field) # e.g city:chicago
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("city ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.downcase }.join(" ")
                query = query.where(Sequel.lit("lower(city) like ?", "#{value}%"))
              end
            elsif ["name"].include?(field)
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("name ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.downcase }.join(" ")
                query = query.where(Sequel.lit("lower(name) like ?", "#{value}%"))
              end
            elsif ["near"].include?(field) # e.g. near:chicago
              # find city
              city = ::Model::City.where(Sequel.lit("lower(name) like ?", "#{value}%")).first
              if not city
                raise ArgumentError, "city invalid"
              end
              # make point from db geo fields and box using city's bounding box values
              query = query.where(
                Sequel.lit("ST_SetSRID(ST_MakePoint(lon, lat), 4326) && ST_SetSRID(ST_MakeBox2D(ST_Point(#{city.lon_min}, #{city.lat_min}), ST_Point(#{city.lon_max}, #{city.lat_max})), 4326)")
              )
            elsif ["tag", "tags"].include?(field)
              values = value.split(",").map{ |s| s.to_s.strip.downcase }
              query = query.tagged_with_any(values)
            else
                raise ArgumentError, "field #{field} invalid"
            end
          end

          struct.places = query.order(Sequel.asc(:name)).offset(@offset).limit(@limit).all
        rescue ArgumentError => e
          struct.code = 422
          struct.errors.push(e.message)

          Console.logger.failure(self, e)
        rescue StandardError => e
          struct.code = 500
          struct.errors.push(e.message)

          Console.logger.failure(self, e)
        end

        struct
      end

    end
  end
end
