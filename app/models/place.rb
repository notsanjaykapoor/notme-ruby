# frozen_string_literal: true

module Model
  class Place < ::Sequel::Model
    plugin :dirty
    plugin :validation_helpers

    def validate
      super
      validates_presence [:city, :lat, :lon, :name, :source_id, :source_name]
      validates_unique [:name]
    end

    SOURCE_MANUAL = "manual"
    SOURCE_MAPBOX = "mapbox"

    # scopes

    dataset_module do
      def city_eq(s)
        where(city: s)
      end

      def city_like(s)
        where(Sequel.lit("city ilike ?", "%#{s}%"))
      end

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
    end # end scopes

    def city_lower
      city.downcase.gsub(" ", "-")
    end

    def city_slug
      city_lower.gsub(" ","-")
    end

    def geo_json_compact(color:)
      {
        "type" => "Feature",
        "geometry" => {
          "coordinates" => [lon, lat],
          "type"=>"Point",
        },
        "properties" => {
          "city" => city,
          "color" => color,
          "name" => name,
        },
      }
    end

    def notes
      data.fetch("notes", "")
    end

    def notes=(s)
      data["notes"] = s
    end

    def notes_size
      notes.length
    end

    def tags
      super || []
    end

    def tags=(list)
      super(TagList.new.normalize(tags: list))
    end

    def updated_at_unix
      updated_at.to_i
    end

  end
end