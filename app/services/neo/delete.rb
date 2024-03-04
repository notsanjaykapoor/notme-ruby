# frozen_string_literal: true

require "neo4j-ruby-driver"

# cypher delete docs: https://neo4j.com/docs/cypher-manual/current/clauses/delete/

module Service
  module Neo

    def self.delete_all(session:)
      #
      # delete all nodes and relationships
      #

      session.write_transaction do |tx|
        tx.run("match (n) detach delete n")
      end

      0
    end

  end
end