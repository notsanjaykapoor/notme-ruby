class GqlQueryRoot < GraphQL::Schema::Object
  # root level query

  field :stocks_list, ::GqlResponses::StocksList, null: false, camelize: false do
    description "list stocks"
    argument :query, String, required: true, camelize: false
    argument :offset, Integer, required: false, camelize: false
    argument :limit, Integer, required: false, camelize: false
  end

  #
  # resolvers
  #

  def stocks_list(query:, offset: 0, limit: 20)
    ::GqlService::Stocks::List.new(
      query: query,
      offset: offset,
      limit: limit,
    ).call
  end

end
