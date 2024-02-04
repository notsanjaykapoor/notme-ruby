class GqlSchema < GraphQL::Schema
  mutation(GqlMutationRoot)
  query(GqlQueryRoot)

  # instrument(:query, ::GqlMetrics)

  # if ENV["RACK_ENV"][/development/]
  #   # create analyzers to log data
  #
  #   GraphQL::Analysis::QueryComplexity.new do |query, complexity|
  #     Log::Factory.instance.info(
  #       name: "graphql_analyzer",
  #       complexity: complexity,
  #     )
  #   end.tap do |object|
  #     query_analyzer(object)
  #   end
  #
  #   GraphQL::Analysis::QueryDepth.new do |query, depth|
  #     Log::Factory.instance.info(
  #       name: "graphql_analyzer",
  #       depth: depth,
  #     )
  #   end.tap do |object|
  #     query_analyzer(object)
  #   end
  # end
end
