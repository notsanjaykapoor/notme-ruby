# frozen_string_literal: true

module Service
  module Places
    class Search

      def initialize(query:, offset:, limit:, near: nil)
        @query = query
        @offset = offset
        @limit = limit
        @near = near

        @struct = Struct.new(:code, :city_name, :places, :tags, :total, :errors)
      end

      def call
        struct = @struct.new(0, "", [], [], 0, [])

        Console.logger.info(self, "#{Thread.current[:rid]} query #{@query}")

        begin
          struct_tokens = ::Service::Database::QueryTokens.new(
            query: @query
          ).call

          tokens = struct_tokens.tokens
          query = ::Model::Place

          if @near
            # add city scope
            query = query.where(Sequel.lit("lower(city) like ?", "#{@near.name_lower}%"))
          end

          tokens.each do |object|
            field = object[:field]
            value = object[:value]

            if ["city"].include?(field) # e.g city:chicago, city:1
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("city ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ")
                if value.match(/^[\d,]+$/)
                  city_ids = value.split(" ").map{ |s| s.to_i }
                  city_names = ::Model::City.where(id: city_ids).map{ |o| o.name }
                  city_name = city_names[0].downcase
                  query = query.where(Sequel.lit("lower(city) like ?", "#{city_name}%"))
                else
                  city_name = value.split(" ").map{ |s| s.downcase }.join(" ")
                  query = query.where(Sequel.lit("lower(city) like ?", "#{city_name}%"))
                end
                struct.city_name = city_name
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
                struct.code = 422
                struct.errors.push("city invalid")
                return struct
              end
              # make point from db geo fields and box using city's bounding box values
              query = query.where(
                Sequel.lit("ST_SetSRID(ST_MakePoint(lon, lat), 4326) && ST_SetSRID(ST_MakeBox2D(ST_Point(#{city.lon_min}, #{city.lat_min}), ST_Point(#{city.lon_max}, #{city.lat_max})), 4326)")
              )
            elsif ["tag", "tags"].include?(field)
              values = value.split(",").map{ |s| s.to_s.strip.downcase }
              query = query.tagged_with_any(values)
              struct.tags.concat(values)
            else
              struct.code = 422
              return struct
            end
          end

          struct.total = query.count
          struct.places = query.order(Sequel.asc(:name)).offset(@offset).limit(@limit).all
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
