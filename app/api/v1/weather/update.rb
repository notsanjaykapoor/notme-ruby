# frozen_string_literal: true

module Api
  module V1
    module Weather
      class Update

        def initialize(request:, response:)
          @request = request
          @response = response

          @params = @request.params
          @city = @params["city"]
          @method = @request.request_method.downcase

          @response.status = 200
        end

        def call
          Console.logger.info(self, "city #{@city}")

          city = ::City.first(name: @city)

          if city.blank? && @method[/put/]
            @response.status = 404

            return {
              message: "city not found",
            }
          end

          # get weather

          struct_get = ::Services::Weather::Api::Get.new(
            query: city ? city.name : @city,
          ).call

          if struct_get.nonzero?
            @response.status = struct_get.code

            return {
              message: struct_get.errors.join(", ")
            }
          end

          # create or update city

          struct_update = ::Service::City::Update.new(
            object: struct_get.data
          ).call

          if struct_update.code.nonzero?
            @response.status = struct_update.code

            return {
              message: struct_update.errors.join(", ")
            }
          end

          {}
        end

      end
    end
  end
end
