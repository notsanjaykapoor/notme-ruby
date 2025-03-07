# frozen_string_literal: true

module Service
  module City
    class Tags

      def self.tags_set_by_city(city_name:)
        Model::Place.where(city: city_name).select(:tags).all().inject(Set[]) { |s, o| s.merge(o.tags) }
      end

      def self.tags_set_all
        Model::Place.select(:tags).all().inject(Set[]) { |s, o| s.merge(o.tags) }
      end

    end
  end
end
