# frozen_string_literal: true

require "neo4j-ruby-driver"

module Service
  module Neo

    def self.driver(url: "")
      url = url == "" ? ENV["NEO4J_URL"] : url
      yield Neo4j::Driver::GraphDatabase.driver(url)
    end

  end
end