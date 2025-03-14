# frozen_string_literal: true

module Model
  class Region < ::Sequel::Model
    plugin :dirty
    plugin :validation_helpers

    def validate
      super
      validates_presence [:lat, :lon, :name, :type]
      validates_unique [:name]
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
      if type == "country"
        6
      elsif type == "continent"
        4
      else
        4
      end
    end

    def name_lower
      name.downcase
    end

    def name_slug
      name.slugify
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