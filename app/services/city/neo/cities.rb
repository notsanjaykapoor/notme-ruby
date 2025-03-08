# frozen_string_literal: true

require "neo4j-ruby-driver"

module Service
  module City
    module Neo

      def self.cities_all(session:)
        # 
        # get all city nodes
        #

        neo_query = "match (node:city) return node"
        neo_result = session.run(neo_query)
        neo_result.to_a
      end

    end
  end
end