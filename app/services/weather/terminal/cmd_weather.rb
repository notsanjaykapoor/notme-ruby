# frozen_string_literal: true

module Services
  module Weather
    module Terminal
      class CmdWeather

        def initialize(city:)
          @city = city

          @struct = Struct.new(:code, :message)
        end

        def call
          struct = @struct.new(0, nil)

          # get weather

          struct_get = ::Services::Weather::Api::Get.new(
            query: @city
          ).call

          if (code = struct_get.code) > 0
            struct.code = code
            struct.message = struct_get.errors.join(", ")

            return struct
          end

          # update database

          struct_update = ::Service::City::Update.new(
            object: struct_get.data
          ).call

          if struct_update.code.nonzero?
            struct.code = struct_update.code
            struct.message = struct_update.errors.join(", ")

            return struct
          end

          struct.message = "#{@city} temp #{struct_update.temp}"

          struct
        end

      end
    end
  end
end
