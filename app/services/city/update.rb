# frozen_string_literal: true

module Service
  module City
    class Update

      def initialize(object:)
        @object = object
        @name = @object.dig("name")

        @struct = Struct.new(:code, :city_id, :temp, :errors)
      end

      def call
        struct = @struct.new(0, nil, 0.0, [])

        Console.logger.info(self, "#{Thread.current[:rid]} city '#{@name}'")

        begin
          city = ::Model::City.first(name: @name)

          if city.blank?
            # create city
            create_params = {
              country: @object["sys"]["country"],
              name: @name,
              temp: @object["main"]["temp"],
            }.merge(@object["coord"]) # lat, lon

            city = ::Model::City.create(create_params)
          end

          # update city weather data

          data = {
            main: @object["main"],
            sys: @object["sys"],
            timezone: @object["timezone"],
            weather: @object["weather"],
          }

          city.update(
            data: data,
            temp: @object["main"]["temp"],
            updated_at: Time.now.utc,
          )

          struct.city_id = city.id
          struct.temp = @object["main"]["temp"]
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
  