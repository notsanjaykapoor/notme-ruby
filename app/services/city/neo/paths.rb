# frozen_string_literal: true

require "neo4j-ruby-driver"

# cypher path docs: https://neo4j.com/docs/cypher-manual/current/patterns/concepts/#path-patterns

module Service
  module City
    module Neo

      def self.path_bfs(session:, city_src:, max_depth:)
        # note: gds isn't imported so this doesn't work
        # neo_result = session.run(
        #   "match (source:city{name:'#{city_src.name}'})
        #    call gds.bfs.stream('myGraph', {sourceNode: source, maxDepth: #{max_depth}})
        #    yield path
        #    return path
        #   ",
        # )

        neo_result = session.run(
          "match path=(src:city)-[r:train*1..#{max_depth}]-(dst:city)
           where src.name = '#{city_src.name}' and dst.name <> '#{city_src.name}'
           return path, reduce(duration=0, r in relationships(path) | duration+r.duration) AS duration
           order by duration asc",
        )

        neo_result.to_a
      end

      def self.path_shortest(session:, city_src:, city_dst:, max_depth:)
        #
        # find the shortest path between 2 cities
        #

        # neo_result = session.run(
        #   "match
        #    path=shortestPath((src:city {name: $name_src})-[:train*]-(dst:city where (dst.name = $name_dst)))
        #    return path",
        #   name_src: city_src.name,e
        #   name_dst: city_dst.name,
        # )

        neo_result = session.run(
          "match path=((src:city)-[:train*1..#{max_depth}]-(dst:city))
           where src.name = '#{city_src.name}' and dst.name = '#{city_dst.name}'
           return path, reduce(duration=0, r in relationships(path) | duration+r.duration) AS duration
           order by duration asc limit 1"
        )

        neo_result.to_a[0]
      end

      def self.paths_all(session:, city_src:, city_dst:, max_depth:)
        #
        # find all paths between 2 cities
        #

        neo_result = session.run(
          "match path=(src:city)-[r:train*1..#{max_depth}]-(dst:city)
           where (src.name = '#{city_src.name}') and (dst.name = '#{city_dst.name}')
           return path, reduce(duration=0, r in relationships(path) | duration+r.duration) AS duration
           order by duration asc"
        )

        # return all result records
        neo_result.to_a
      end

    end
  end
end

