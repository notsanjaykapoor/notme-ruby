require "minitest/autorun"
require "test_helper"

class DatabaseQueryTest < Minitest::Test

    def test_query_uses_default_field
      query = ::Service::Database::Query.normalize(query: "chicago", default_field: "city", default_match: "exact")
      assert_equal query, "city:chicago"     

      query = ::Service::Database::Query.normalize(query: "chicago", default_field: "city", default_match: "like")
      assert_equal query, "city:~chicago"     

      query = ::Service::Database::Query.normalize(query: "food city:chi", default_field: "name", default_match: "exact")
      assert_equal query, "name:food city:chi"     
    end

    def test_query_with_field
      query = ::Service::Database::Query.normalize(query: "name:~chicago", default_field: "city", default_match: "exact")
      assert_equal query, "name:~chicago"     
    end

    def test_tokens_with_mode
      # raw mode will not change values
      struct_tokens = ::Service::Database::QueryTokens.new(query: "brands:ma+,yuta-m", mode: "raw").call
      tokens = struct_tokens.tokens

      assert_equal tokens.length, 1

      assert_equal tokens[0], {field: "brands", value: "ma+,yuta-m"}

      # modify mode will change hyphens and spaces
      struct_tokens = ::Service::Database::QueryTokens.new(query: "brands:ma+,yuta-m", mode: "modify").call
      tokens = struct_tokens.tokens

      assert_equal tokens.length, 1

      assert_equal tokens[0], {field: "brands", value: "ma ,yuta m"}
    end

  end