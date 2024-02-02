# frozen_string_literal: true

require "http"

module Service
  module Plaid
    module Tokens
      class LinkCreate

        #
        # create a link_token, which is required as a parameter when initializing Link
        #
        # docs: https://plaid.com/docs/api/tokens/#linktokencreate
        #

        def initialize(client_name:, user_id:)
          @client_name = client_name
          @user_id = user_id

          @user = {
            client_user_id: @user_id,
          }

          @client_id = ENV["PLAID_CLIENT_ID"]
          @secret = ENV["PLAID_SECRET"]

          @country_codes = ["US"]
          @language = "en"
          @products = ["transactions"]

          @http = ::HTTP
          @endpoint = "#{ENV["PLAID_URI"]}/link/token/create"

          @struct = Struct.new(:code, :token, :object, :error)
        end

        def call
          struct = @struct.new(0, nil, {}, {})

          params = {
            client_id: @client_id,
            client_name: @client_name,
            country_codes: @country_codes,
            language: @language,
            products: @products,
            secret: @secret,
            user: @user,
          }.compact

          response = @http.post(@endpoint, json: params)
          object = Oj.load(response)

          if response.code > 299
            struct.code = response.code
            struct.error = object # error hash

            return struct
          end

          struct.object = object
          struct.token = struct.object["link_token"]

          struct
        end

      end
    end
  end
end