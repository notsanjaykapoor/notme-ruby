# frozen_string_literal: true

require "tilt"
require "tilt/erb"

module Service
  module Stock
    class Watch

      def initialize(conn:, queue:, expires_unix:)
        @conn = conn
        @queue = queue
        @expires_unix = expires_unix

        @finance_data = ENV["APP_FINANCE_DATA"]
        @symbols = []
        @queue_check_interval = 1
        @watch_check_interval = 30
      end

      def call
        Console.logger.info(self, "watch starting")

        time_unix = Time.now.utc.to_i
        watch_changed = 0
        watch_expired = 0

        while true do
          if not @queue.empty?
            watch_changed = _queue_message_handle
          end

          sleep(@queue_check_interval)

          seconds_elapsed = Time.now.utc.to_i - time_unix

          if (Time.now.utc.to_i >= @expires_unix) and (watch_expired == 0)
            watch_expired = 1
            _watch_status_render(status: "expired")
            Console.logger.info(self, "watch expired at #{@expires_unix}")
          end

          if (seconds_elapsed > @watch_check_interval) || (watch_changed == 1)
            if @symbols.length == 0
              Console.logger.info(self, "watch empty")
            elsif watch_expired == 1
              _watch_status_render(status: "expired")
              Console.logger.info(self, "watch expired")
            else
              _stock_prices_fetch
            end

            time_unix = Time.now.utc.to_i
          end

          watch_changed = 0
        end
      end

      def _queue_message_handle
        message_json = @queue.dequeue
        message_hash = JSON.parse(message_json.to_str).transform_keys{ |key| key.to_s.downcase.to_sym }

        Console.logger.info(self, "#{message_hash}")

        case message_hash
        in {topic: /^finance:watch/i, data:, expires_unix:} # matches topic with data and expired_unix values 
          @symbols = (data or "").split(",").map{ |s| s.strip.upcase }
          @expires_unix = expires_unix

          1
        in {headers:} # matches htmx ws headers request
          uri = URI.parse(headers.dig("HX-Current-URL"))

          if not uri.query
            return 0
          end

          query = Rack::Utils.parse_query(uri.query)
          data = query.dig("q") or ""
          @symbols = data.split(",").map{ |s| s.strip.upcase }

          1
        else
          0
        end
      end

      def _stock_prices_fetch
        if @finance_data == "twelve"
          struct_price = ::Service::Twelve::Price.new(symbols: @symbols).call
        else
          struct_price = ::Service::Twelve::PriceRandom.new(symbols: @symbols).call
        end

        # render template and send to client
        template = ::Tilt::ERBTemplate.new("./views/ticker/table_ws.erb")
        output = template.render(Hash, {stocks: struct_price.data})

        @conn.write(output)
        @conn.flush

        0
      end

      def _watch_status_render(status:)
        # render template and send to client
        template = ::Tilt::ERBTemplate.new("./views/ticker/expired_ws.erb")
        output = template.render(Hash, {status: "expired"})

        @conn.write(output)
        @conn.flush

        0
      end

    end
  end
end
  