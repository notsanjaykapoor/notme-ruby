# frozen_string_literal: true

module Service
  module City
    class Update

      def initialize(data:)
        @data = data
        @name = @data.dig("name")

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
              bbox: @data.dig("boundingbox") || [],
              country_code: @data["address"]["country_code"].to_s.upcase,
              lat: @data["lat"].to_f,
              lon: @data["lon"].to_f,
              name: @name,
            }

            city = ::Model::City.create(create_params)
          end

          # update city weather data

          city.update(
            data: @data,
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
  