# frozen_string_literal: true

require "neo4j-ruby-driver"

# cypher constraints docs: https://neo4j.com/docs/cypher-manual/current/constraints/syntax/

module Service
  module Neo

    def self.init(session:)
      #
      # initialize city node constraints
      #

      session.write_transaction do |tx|
        tx.run("create constraint city_name_unique if not exists for (n:city) require n.name is node unique")
      end

      0
    end

  end
end