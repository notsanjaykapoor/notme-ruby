class GqlQueryRoot < GraphQL::Schema::Object
  # root level query

  field :auth_pki, ::GqlResponses::AuthPki, null: false, camelize: false do
    description "authenticate user with pki credentials"
    argument :user_id, String, required: true, camelize: false
    argument :message, String, required: true, camelize: false
    argument :signature, String, required: true, camelize: false
  end

  field :stocks_list, ::GqlResponses::StocksList, null: false, camelize: false do
    description "list stocks"
    argument :query, String, required: true, camelize: false
    argument :offset, Integer, required: false, camelize: false
    argument :limit, Integer, required: false, camelize: false
  end

  #
  # resolvers
  #

  def auth_pki(user_id:, message:, signature:)
    ::GqlService::Auth::Pki.new(
      user_id: user_id,
      message: message,
      signature: signature,
    ).call
  end

  def stocks_list(query:, offset: 0, limit: 20)
    ::GqlService::Stocks::List.new(
      query: query,
      offset: offset,
      limit: limit,
    ).call
  end

end
