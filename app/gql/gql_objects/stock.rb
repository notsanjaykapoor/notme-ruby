module GqlObjects
  class Stock < GraphQL::Schema::Object
    field :name, String, null: true
    field :price, Float, null: true
    field :tags, [String], null: false
    field :ticker, String, null: false
  end
end
