class GqlQueryRoot < GraphQL::Schema::Object
  # root level query

  field :stocks_list, ::GqlResponses::StocksList, null: false, camelize: false do
    description "list stocks"
    argument :query, String, required: true, camelize: false
  end

  #
  # resolvers
  #

  def stocks_list(query:)
    ::GqlService::Stocks::List.new(
      query: query,
    ).call
  end

end
