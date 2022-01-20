module GqlObjects
  class City < GraphQL::Schema::Object
    field :feels_like, Float, null: true, camelize: false
    field :name, String, null: false
    field :lat, Float, null: false
    field :lon, Float, null: false
    field :tags, [String], null: false
    field :temp, Float, null: false
    field :temp_max, Float, null: true, camelize: false
    field :temp_min, Float, null: true, camelize: false
    field :updated_at_unix, Integer, null: false, camelize: false
    field :weather, String, null: false
  end
end
