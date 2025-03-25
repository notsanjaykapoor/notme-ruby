# frozen_string_literal: true

module Service
  module City
    class Update

      def initialize(name:, geo_json:)
        @name = name
        @geo_json = geo_json
        @geo_props = geo_json.fetch("properties")
        @geo_coords = geo_json.dig("geometry", "coordinates")

        @struct = Struct.new(:code, :city, :errors)
      end

      def call
        struct = @struct.new(0, nil, [])

        Console.logger.info(self, "#{Thread.current[:rid]} city '#{@name}'")

        begin
          city = ::Model::City.first(name: @name)

          if city.blank?
            # create city
            create_params = {
              bbox: @geo_json.fetch("bbox", []),
              country_code: @geo_props.fetch("country_code").to_s.upcase,
              lat: @geo_coords[1].to_f,
              lon: @geo_coords[0].to_f,
              name: @name,
            }

            city = ::Model::City.create(create_params)
          end

          # update city weather data

          city.update(
            data: @geo_json,
            updated_at: Time.now.utc,
          )

          struct.city = city
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
  