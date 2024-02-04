# frozen_string_literal: true

module Service
  module City
    class Resolve

      def initialize(name:, offset:, limit:)
        @name = name
        @offset = offset
        @limit = limit

        @struct = Struct.new(:code, :city, :errors)
      end

      def call
        struct = @struct.new(0, {}, [])

        Console.logger.info(self, "#{Thread.current[:rid]} name '#{@name}'")

        if @name == ""
          struct.code = 404

          struct
        end

        struct_list = ::Service::City::Search.new(query: "name:~#{@name}", offset: 0, limit: 5).call

        if struct_list.cities.length == 0
          struct.code = 404

          struct
        end

        city_id = struct_list.cities[0].dig(:id)
        struct.city = ::Model::City.first(id: city_id)

        struct
      end

    end
  end
end

