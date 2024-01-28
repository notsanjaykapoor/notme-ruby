# frozen_string_literal: true

module GqlService
  module Auth
    class Pki

      def initialize(user_id:, message:, signature:)
        @user_id = user_id
        @message = message
        @signature = signature

        @struct = Struct.new(:code, :user_id, :errors)
      end

      def call
        struct = @struct.new(0, @user_id, [])

        Console.logger.info(self, "#{Thread.current[:rid]} user_id #{@user_id}")

        struct_auth = ::Service::Auth::Pki.new(
          user_id: @user_id,
          message: @message,
          signature: @signature,
        ).call

        struct.code = struct_auth.code
        struct.user_id = struct_auth.user_id
        struct.errors = struct_auth.errors

        Console.logger.info(self, "#{Thread.current[:rid]} user_id #{@user_id} code #{struct.code}")

        struct
      end

    end
  end
end
