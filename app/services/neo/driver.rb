# frozen_string_literal: true

require "neo4j-ruby-driver"

module Service
  module Neo

    def self.driver(url: "")
      url_ = (url == "") ? ENV["NEO4J_URL"] : url
      yield Neo4j::Driver::GraphDatabase.driver(url_)
    end

    def self.driver_get(url: "")
      url_ = (url == "") ? ENV["NEO4J_URL"] : url
      Neo4j::Driver::GraphDatabase.driver(url_)
    end

  end
end