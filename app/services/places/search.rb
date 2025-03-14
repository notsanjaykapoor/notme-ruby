# frozen_string_literal: true

module Service
  module Places
    class Search

      def initialize(query:, offset:, limit:, box: nil)
        @query = query
        @offset = offset
        @limit = limit
        @box = box

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

          if @box
            # add token to query string
            tokens.push({
              field: "box",
              value: @box.name_lower,
            })
          end

          tokens.each do |object|
            field = object[:field]
            value = object[:value]

            if ["box"].include?(field) # e.g. box:chicago, box:europe
              # find city or region
              object = ::Model::City.where(Sequel.lit("lower(name) like ?", "#{value}%")).first || 
                ::Model::Region.where(Sequel.lit("lower(name) like ?", "#{value}%")).first

              if not object
                struct.code = 422
                struct.errors.push("city invalid")
                return struct
              end

              # make point from db geo fields and box using object's bounding box values
              query = query.where(
                Sequel.lit("ST_SetSRID(ST_MakePoint(lon, lat), 4326) && ST_SetSRID(ST_MakeBox2D(ST_Point(#{object.lon_min}, #{object.lat_min}), ST_Point(#{object.lon_max}, #{object.lat_max})), 4326)")
              )
            elsif ["city"].include?(field) # e.g city:chicago, city:1
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
            elsif ["country"].include?(field)
              if value.length == 2
                country_code = value.upcase
              else
                # map country name to country code
                country_code = ::Service::Country::Search.map_name_to_code(name: value).upcase
              end
              query = query.where(country_code: country_code)
            elsif ["name"].include?(field)
              if value[/^~/]
                value = value.gsub(/~/, '')
                query = query.where(Sequel.lit("name ilike ?", "%#{value}%"))
              else
                value = value.gsub(/-/, " ").split(" ").map{ |s| s.downcase }.join(" ")
                query = query.where(Sequel.lit("lower(name) like ?", "#{value}%"))
              end
            elsif ["mappable"].include?(field) # e.g. mappable:0|1
              query = query.mappable(value)
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

          Console.logger.error(self, e)
        end

        struct
      end

    end
  end
end
