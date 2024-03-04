# frozen_string_literal: true

require "neo4j-ruby-driver"

# cypher create docs: https://neo4j.com/docs/cypher-manual/current/clauses/create/

module Service
  module City
    module Neo

      def self.node_create(session:, city:)
        #
        # create city node
        #

        neo_result = session.run("match (n:city {name: '#{city.name}'}) return count(n)").single

        if neo_result.values[0] > 0
          return 429
        end

        session.write_transaction do |tx|
          country = city.data.dig("address", "country") or ""
          lat = city.lat.to_f
          lon = city.lon.to_f

          tx.run("create (n:city {country: '#{country}', lat:#{lat}, lon:#{lon}, name:'#{city.name}'})")
        end

        0
      end

      def self.train_create(session:, city_src:, city_dst:, duration:)
        #
        # create train relationship between cities
        #

        session.write_transaction do |tx|
          tx.run(
            "match (src:city {name:'#{city_src.name}'}), (dst:city {name:'#{city_dst.name}'})
             merge (src)-[:train {duration:#{duration.to_f}}]->(dst)",
          )
        end

        0
      end

    end
  end
end