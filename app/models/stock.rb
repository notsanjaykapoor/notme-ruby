# frozen_string_literal: true

module Model
  class Stock < ::Sequel::Model
    plugin :dirty
    plugin :validation_helpers

    def validate
      super
      validates_presence [:ticker, :price]
      validates_unique [:ticker]
    end

    # scopes

    dataset_module do
      def name_eq(s)
        where(name: s)
      end

      def name_like(s)
        where(Sequel.lit("name ilike ?", "%#{s}%"))
      end

      def price_gte(s)
        where(Sequel.lit("price >= ?", s.to_f))
      end

      def price_lte(s)
        where(Sequel.lit("price <= ?", s.to_f))
      end

      # tagged with all tags in list
      def tagged_with_all(list)
        where(Sequel.pg_array(:tags).contains(Array(list)))
      end

      # tagged with any tag in list
      def tagged_with_any(list)
        where(Sequel.pg_array(:tags).overlaps(Array(list)))
      end

      def ticker_eq(s)
        where(ticker: s.to_s.upcase)
      end

      def ticker_like(s)
        where(Sequel.lit("ticker like ?", "%#{s.to_s.upcase}%"))
      end
    end

    def tags
      super || []
    end

    def tags=(list)
      super(TagList.new.normalize(tags: list))
    end

  end
end