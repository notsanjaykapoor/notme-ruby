module GqlObjects
  class Stock < GraphQL::Schema::Object
    field :name, String, null: true
    field :price, Float, null: true
  end
end
