module GqlResponses
  class AuthPki < GraphQL::Schema::Object
    field :code, Integer, null: false, camelize: false
    field :user_id, String, null: true, camelize: false
    field :errors, [String], null: false, camelize: false
  end
end
