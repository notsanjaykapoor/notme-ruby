# frozen_string_literal: true

module Service
  module Database
    module Query

      def self.normalize(query:, default_field:, default_match:)
        if query.to_s.strip == ""
          return ""
        end

        tokens = query.strip.split(" ")

        if tokens[0].match(":")
          # looks like a valid query with field:value tokens
          return query
        end

        if default_match == "like"
          tokens[0] = "#{default_field}:~#{tokens[0]}"
        else
          tokens[0] = "#{default_field}:#{tokens[0]}"
        end

        return tokens.join(" ")
      end

    end
  end
end
