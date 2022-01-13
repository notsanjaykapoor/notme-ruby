class GqlMutationRoot < GraphQL::Schema::Object

  # NOTE: mutation must have at least 1 field to avoid it throwing an exception
  field :test_field, String, null: false,
    description: "An example field added by the generator"
  def test_field
    "Hello World"
  end

end
