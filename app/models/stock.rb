# frozen_string_literal: true

class Stock < ::Sequel::Model
  plugin :dirty
  plugin :update_or_create
  plugin :validation_helpers

  def validate
    super
    validates_presence [:name, :price]
    validates_unique [:name]
  end

  # scopes

  dataset_module do
    def name_eq(s)
      where(name: s)
    end

    def name_like(s)
      where(Sequel.lit("name like ?", "%#{s.to_s.downcase}%"))
    end

    def price_gte(s)
      where(Sequel.lit("price >= ?", s.to_f))
    end

    def price_lte(s)
      where(Sequel.lit("price <= ?", s.to_f))
    end
  end

end
