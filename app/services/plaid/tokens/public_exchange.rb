# frozen_string_literal: true

require "http"

module Service
  module Plaid
    module Tokens
      class PublicExchange

        #
        # exchange a public token for an access token
        #
        # docs: https://plaid.com/docs/api/tokens/#itempublic_tokenexchange
        #

        def initialize(public_token:)
          @public_token = public_token

          @client_id = ENV["PLAID_CLIENT_ID"]
          @secret = ENV["PLAID_SECRET"]

          @http = ::HTTP
          @endpoint = "#{ENV["PLAID_URI"]}/item/public_token/exchange"

          @struct = Struct.new(:code, :token, :object, :error)
        end

        def call
          struct = @struct.new(0, nil, {}, {})

          params = {
            client_id: @client_id,
            public_token: @public_token,
            secret: @secret,
          }.compact

          response = @http.post(@endpoint, json: params)
          object = Oj.load(response)

          if response.code > 299
            struct.code = response.code
            struct.error = object # error hash

            return struct
          end

          struct.object = object
          struct.token = struct.object["access_token"]

          struct
        end

      end
    end
  end
end