require "async"
require "async/websocket/adapters/rack"

# boot app

require "./boot.rb"

app = lambda do |env|
  Async::WebSocket::Adapters::Rack.open(env, protocols: ["ws"]) do |connection|
    Console.logger.info("WebSocket", "connected")

    # create terminal queues

    input_queue = ::Async::Queue.new
    output_queue = ::Async::Queue.new

    ::Services::Terminal::Parse.new(
      input_queue: input_queue,
      output_queue: output_queue,
    ).call

    Async do
      # read message and send to terminal
      while message = connection.read
        input_queue.enqueue(message)
      end
    end

    # block on terminal output and send via websocket
    while message = output_queue.dequeue
      connection.write(message)
      connection.flush
    end
  end
end

run app
