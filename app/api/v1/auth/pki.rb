# frozen_string_literal: true

module Api
  module V1
    module Auth
      class Pki

        PKI_DIR = "./pki"

        def initialize(request:, response:)
          @request = request
          @response = response

          @params = @request.params
          @message = @request["message"] # json object
          @signature = @request["signature"] # base58 string

          @key_path = "#{PKI_DIR}/#{@user_id}.pub.pem"

          @response.status = 200
        end

        def call
          Console.logger.info(self, "#{Thread.current[:rid]} message #{@message.to_s}")

          struct_auth = ::Service::Auth::Pki.new(
            message: @message,
            signature: @signature,
          ).call

          Console.logger.info(self, "#{Thread.current[:rid]} code #{struct_auth.code}")

          if struct_auth.code.nonzero?
            @response.status = struct_auth.code
          end

          {
            code: struct_auth.code,
            user_id: struct_auth.user_id,
            errors: struct_auth.errors,
          }
        end

      end
    end
  end
end
