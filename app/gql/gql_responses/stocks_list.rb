module GqlResponses
  class StocksList < GraphQL::Schema::Object
    field :code, Integer, null: false
    field :stocks, [::GqlObjects::Stock], null: false, camelize: false
    field :errors, [String], null: false
  end
end
