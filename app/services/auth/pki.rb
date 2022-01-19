# frozen_string_literal: true

module Services
  module Auth
    class Pki

      PKI_DIR = "./pki"

      def initialize(user_id:, message:, signature:)
        @user_id = user_id
        @message = message
        @signature = signature

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

          openssl_key = OpenSSL::PKey::RSA.new(File.read(@key_path))

          result = openssl_key.verify(
            OpenSSL::Digest::SHA256.new,
            Base58.base58_to_binary(@signature), # convert base58 to binary
            @message
          )

          if !result
            struct.code = 400
            struct.errors.push("invalid signature")

            return struct
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
