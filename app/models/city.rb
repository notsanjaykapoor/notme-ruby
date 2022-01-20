# frozen_string_literal: true

class City < ::Sequel::Model
  plugin :dirty
  plugin :validation_helpers

  def validate
    super
    validates_presence [:lat, :lon, :name, :temp]
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

    def temp_gte(s)
      where(Sequel.lit("temp >= ?", s.to_f))
    end

    def temp_lte(s)
      where(Sequel.lit("temp <= ?", s.to_f))
    end
  end

  def feels_like
    data.dig("main", "feels_like")
  end

  def tags
    super || []
  end

  def tags=(list)
    super(TagList.new.normalize(tags: list))
  end

  def temp_max
    data.dig("main", "temp_max")
  end

  def temp_min
    data.dig("main", "temp_min")
  end

  def updated_at_unix
    updated_at.to_i
  end

  def weather
    data.dig("weather", 0, "description").to_s
  end

end
