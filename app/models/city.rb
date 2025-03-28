# frozen_string_literal: true

module Model
  class City < ::Sequel::Model
    plugin :dirty
    plugin :validation_helpers

    def validate
      super
      validates_presence [:lat, :lon, :name]
      validates_unique [:name]
    end

    # scopes

    dataset_module do
      def name_eq(s)
        where(name: s)
      end

      def name_like(s)
        where(Sequel.lit("name ilike ?", "%#{s}%"))
      end

      # tagged with all tags in list
      def tagged_with_all(list)
        where(Sequel.pg_array(:tags).contains(Array(list)))
      end

      # tagged with any tag in list
      def tagged_with_any(list)
        where(Sequel.pg_array(:tags).overlaps(Array(list)))
      end
    end

    def lat_min
      bbox[0]
    end

    def lat_max
      bbox[1]
    end

    def lon_min
      bbox[2]
    end

    def lon_max
      bbox[3]
    end

    def map_zoom
      10
    end

    def name_lower
      name.downcase
    end

    def name_slug
      name_lower.gsub(" ","-")
    end

    def tags
      super || []
    end

    def tags=(list)
      super(TagList.new.normalize(tags: list))
    end

    def type
      "city"
    end

    def updated_at_unix
      updated_at.to_i
    end

  end
end
