# frozen_string_literal: true

module Services
  module Weather
    module Terminal
      class Parse

        TOKEN_REGEX = /[^a-zA-Z0-9_\.]+/ # \W + period

        def initialize(cmd:)
          @cmd = cmd.to_s

          @struct = Struct.new(:code, :errors, :message)
        end

        def call
          struct = @struct.new(0, [], nil)

          # parse cmd into tokens

          tokens = @cmd.split(TOKEN_REGEX)

          struct_parse_tokens = ::Services::Weather::Terminal::ParseTokens.new(
            tokens: tokens
          ).call

          struct.code = struct_parse_tokens.code
          struct.message = struct_parse_tokens.message

          struct
        end

      end
    end
  end
end
