# frozen_string_literal: true

module Service
  module Weather
    class Update

      def initialize(object:)
        @object = object
        @name = @object.dig("name")

        @struct = Struct.new(:code, :weather_id, :temp, :errors)
      end

      def call
        struct = @struct.new(0, 0, 0.0, [])

        Console.logger.info(self, "#{Thread.current[:rid]} city '#{@name}'")

        begin
          weather = ::Model::Weather.first(name: @name)

          if weather.blank?
            # create
            create_params = {
              country_code: @object["sys"]["country"],
              name: @name,
              temp: @object["main"]["temp"],
            }.merge(@object["coord"]) # lat, lon

            weather = ::Model::Weather.create(create_params)
          end

          # update weather data

          data = {
            main: @object["main"],
            sys: @object["sys"],
            timezone: @object["timezone"],
            weather: @object["weather"],
          }

          weather.update(
            data: data,
            temp: @object["main"]["temp"],
            updated_at: Time.now.utc,
          )

          struct.weather_id = weather.id
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
  