module Service
  module Places
    class Tags

      def self.tag_color(tags:)
        # map tags list to a color, used in map views

        if tags.include?("hotel")
          return "green"
        end

        tags_set = tags.to_set

        if tags_set.intersect?(["bar", "food"].to_set)
          "blue"
        elsif tags_set.intersect?(["clothing", "fashion", "shoes"].to_set)
          "orange"
        else
          "yellow"
        end
      end

    end
  end
end
