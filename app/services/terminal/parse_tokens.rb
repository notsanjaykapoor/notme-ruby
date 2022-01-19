# frozen_string_literal: true

module Services
  module Terminal
    class ParseTokens

      def initialize(tokens:)
        @tokens = tokens

        @struct = Struct.new(:code, :cmd, :ticker, :op, :tokens, :message)
      end

      def call
        struct = @struct.new(0, nil, nil, nil, [], nil)

        case @tokens
        in [/stock|ticker/i => cmd, String => ticker, /create|delete|update/i => op, *tokens]
          struct.cmd = cmd.downcase
          struct.ticker = ticker.upcase
          struct.op = op.downcase
          struct.tokens = tokens
        in [/stock|ticker/i, /help/i => cmd, *tokens]
          struct.cmd = cmd.downcase
          struct.tokens = tokens
        in [/help/i => cmd, *tokens]
          struct.cmd = cmd.downcase
          struct.tokens = tokens
        else
          struct.code = 400
          struct.message = "ticker :ticker create|delete|update"
        end

        struct
      end

    end
  end
end
