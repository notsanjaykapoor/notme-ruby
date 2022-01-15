# frozen_string_literal: true

module Api
  module V1
    module Stocks
      class Update

        def initialize(request:, response:, ticker:)
          @request = request
          @response = response
          @ticker = ticker.to_s.upcase

          @params = @request.params
          @name = @params["name"]
          @price = @params["price"].to_f

          @response.status = 200
        end

        def call
          Console.logger.info(self, "ticker #{@ticker}, price #{@price}")

          stock = Stock.update_or_create(ticker: @ticker) do |object|
            object.name = @name
            object.price = @price
          end

          {
            code: 0,
            id: stock.id
          }
        end

      end
    end
  end
end
