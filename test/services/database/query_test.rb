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
      assert_equal query,"name:~chicago"     
    end

end