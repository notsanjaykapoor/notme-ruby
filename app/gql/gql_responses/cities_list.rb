module GqlResponses
  class CitiesList < GraphQL::Schema::Object
    field :code, Integer, null: false
    field :cities, [::GqlObjects::City], null: false, camelize: false
    field :errors, [String], null: false
  end
end
