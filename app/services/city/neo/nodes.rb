# frozen_string_literal: true

require "neo4j-ruby-driver"

module Service
  module City
    module Neo

      def self.nodes_search(query:, session:)
        if not query.match(/:/)
          # normalize query
          query = "city:#{query}"
        end

        struct_tokens = ::Service::Database::QueryTokens.new(
          query: query
        ).call

        where_clause = ""

        tokens = struct_tokens.tokens
        
        tokens.each do |object|
          field = object[:field]
          value = object[:value]

          if field.match(/^city/)
            value = value.gsub(/~/, '')
            where_clause = "where node.name =~ '(?i).*#{value}.*'"
          elsif field.match(/^country/)
            value = value.gsub(/~/, '')
            where_clause = "where node.country =~ '(?i).*#{value}.*'"
          end
        end

        neo_result = session.run(
          "match (node:city)
           #{where_clause}
           return node order by node.country,node.name
          ",
        )

        neo_result.to_a
      end

    end
  end
end

    
    
  