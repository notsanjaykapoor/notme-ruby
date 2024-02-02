require "async"
require "async/websocket/adapters/rack"
require "logger"
require "protocol/websocket/json_message"

# boot app

require "./boot.rb"

app = lambda do |env|
  Async::WebSocket::Adapters::Rack.open(env, protocols: ["ws"]) do |connection|
    Console.logger.info("WebSocket", "connected")

    queue = ::Async::Queue.new

    watch_task = Async do
      ::Service::Stock::Watch.new(
        conn: connection,
        queue: queue,
        expires_unix: Time.now.utc.to_i + 120, # default expires in 2 mins
      ).call
    end

    # read socket messages and add to queue
    while message = connection.read
      queue.enqueue(message)
    end
  rescue Protocol::WebSocket::ClosedError => e
    Console.logger.info("WebSocket", "socket closed")
  rescue StandardError => e
    Console.logger.info("WebSocket", "exception #{e}")
  ensure
    Console.logger.info("WebSocket", "cleanup")
    watch_task&.stop
  end
end

run app
