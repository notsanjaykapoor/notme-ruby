# frozen_string_literal: true

module Services
  module Weather
    class Update

      def initialize(object:)
        @object = object

        @name = @object["name"]

        @struct = Struct.new(:code, :city_id, :errors)
      end

      def call
        struct = @struct.new(0, nil, [])

        begin
          city = City.first(name: @name)

          if city.blank?
            # create city

            create_params = {
              country: @object["sys"]["country"],
              name: @name,
              temp: @object["main"]["temp"],
            }.merge(@object["coord"]) # lat, lon

            city = City.create(create_params)
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
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
