# frozen_string_literal: true

module Api
  module Stocks
    class Update

      def initialize(request:, response:, name:)
        @request = request
        @response = response
        @name = name.to_s.downcase

        @params = @request.params
        @price = @params["price"].to_f

        @topic = self.class.name.underscore

        @response.status = 200
      end

      def call
        Console.logger.info(self, "name:#{@name} price:#{@price}")

        stock = Stock.update_or_create(name: @name) do |object|
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
