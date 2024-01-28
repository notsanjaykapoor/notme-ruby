# frozen_string_literal: true

module Services
  module Weather
    module Terminal
      class ParseTokens

        def initialize(tokens:)
          @tokens = tokens

          @struct = Struct.new(:code, :cmd, :city, :tokens, :message)
        end

        def call
          struct = @struct.new(0, nil, nil, [], nil)

          case @tokens
          in [/weather/i, /help/i => cmd, *tokens]
            struct.cmd = cmd.downcase
            struct.tokens = tokens

            struct.code = 400
            struct.message = "weather :city, e.g. 'weather chicago'"
          in [/weather/i => cmd, *city]
            struct.cmd = cmd.downcase
            struct.city = city.join(" ")

            struct_weather = ::Services::Weather::Terminal::CmdWeather.new(
              city: struct.city
            ).call

            struct.code = struct_weather.code
            struct.message = struct_weather.message
          in [/help/i => cmd, *tokens]
            struct.cmd = cmd.downcase
            struct.tokens = tokens

            struct.code = 400
            struct.message = "weather :city, e.g. 'weather chicago'"
          else
            struct.code = 400
            struct.message = "weather :city, e.g. 'weather chicago'"
          end

          struct
        end

      end
    end
  end
end
