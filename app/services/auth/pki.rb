# frozen_string_literal: true

module Services
  module Auth
    class Pki

      PKI_DIR = "./pki"

      def initialize(message:, signature:)
        @message = message
        @signature = signature

        if !@message.is_a?(Hash)
          raise ArgumentError, "hash expected"
        end

        @user_id = @message["user_id"]
        @key_path = "#{PKI_DIR}/#{@user_id}.pub.pem"

        @struct = Struct.new(:code, :user_id, :errors)
      end

      def call
        struct = @struct.new(0, @user_id, [])

        begin
          if !File.exists?(@key_path)
            struct.code = 400
            struct.errors.push("invalid user")

            return struct
          end

          # verify signature with user's public key

          public_key = OpenSSL::PKey::RSA.new(File.read(@key_path))

          result = public_key.verify(
            OpenSSL::Digest::SHA256.new,
            Base58.base58_to_binary(@signature), # base58 to binary
            @message.to_s, # message digest
          )

          if !result
            struct.code = 400
            struct.errors.push("invalid signature")

            return struct
          end

          if @message[/^#{@user_id}:\d{8}T\d{6}Z$/]
            # check timestamp
            _, timestamp = @message.split(":")

            time_diff = Time.now.utc.to_i - Time.parse(timestamp).to_i

            if !time_diff.between?(0, 300)
              # invalid timestamp
              struct.code = 400
              struct.errors.push("invalid timestamp")

              return struct
            end
          end
        rescue => e
          Console.logger.error(self, e)

          struct.code = 500
          struct.errors.push(e.message)
        end

        struct
      end

    end
  end
end
