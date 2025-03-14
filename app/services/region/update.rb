# frozen_string_literal: true

module Service
  module Region
    class Update

      def initialize(data:)
        @data = data
        @name = @data.fetch("name")

        @struct = Struct.new(:code, :region, :errors)
      end

      def call
        struct = @struct.new(0, nil, [])

        Console.logger.info(self, "#{Thread.current[:rid]} region '#{@name}'")

        begin
          region = ::Model::Region.first(name: @name)

          if region.blank?
            # create region
            create_params = {
              bbox: @data.fetch("boundingbox", []),
              code: @data.dig("address", "country_code").to_s.upcase,
              lat: @data["lat"].to_f,
              lon: @data["lon"].to_f,
              name: @name,
              type: @data.fetch("addresstype"),
            }

            region = ::Model::Region.create(create_params)
          end

          region.update(
            data: @data,
            updated_at: Time.now.utc,
          )

          struct.region = region
        rescue => e
          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
  