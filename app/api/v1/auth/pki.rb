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
          @user_id = @request["user_id"].to_s
          @message = @request["message"].to_s
          @signature = @request["signature"].to_s

          @key_path = "#{PKI_DIR}/#{@user_id}.pub.pem"

          @response.status = 200
        end

        def call
          Console.logger.info(self, "#{Thread.current[:rid]} user_id #{@user_id}")

          struct_auth = ::Services::Auth::Pki.new(
            user_id: @user_id,
            message: @message,
            signature: @signature,
          ).call

          Console.logger.info(self, "#{Thread.current[:rid]} user_id #{@user_id} code #{struct_auth.code}")

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
