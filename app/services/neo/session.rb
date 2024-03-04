# frozen_string_literal: true

require "neo4j-ruby-driver"

module Service
  module Neo

    def self.session(url: "")
      ::Service::Neo::driver(url: url) do |driver|
        driver.session(database: ENV["NEO4J_DB"]) do |session|
          yield session
        end
      end
    end

    def self.session_get(url: "")
      driver = ::Service::Neo::driver_get(url: url)
      driver.session(database: ENV["NEO4J_DB"])
    end

  end
end