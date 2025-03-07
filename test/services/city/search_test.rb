require "minitest/autorun"
require "test_helper"

class CitySearchTest < Minitest::Test
  def setup
    @boston = ::Model::City.create(data: {}, name: "Boston", lat: 42.35, lon: -71.05)
    @chicago = ::Model::City.create(data: {}, name: "Chicago", lat: 41.85, lon: -87.65)
  end

  def teardown
    ::Model::City.truncate
  end

  def test_query_all
    struct = ::Service::City::Search.new(
      query: "",
      offset: 0,
      limit: 10,
    ).call

    assert_equal 0, struct.code
    assert_equal 2, struct.cities.length
    assert_equal 2, struct.total
  end

  def test_query_id_match
    struct = ::Service::City::Search.new(
      query: "id:#{@chicago.id}",
      offset: 0,
      limit: 1,
    ).call

    assert_equal 0, struct.code
    assert_equal 1, struct.cities.length
    assert_equal "Chicago", struct.cities[0].name
    assert_equal 1, struct.total
  end

  def test_query_like_match
    struct = ::Service::City::Search.new(
      query: "name:~chi",
      offset: 0,
      limit: 10,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.cities.length, 1
  end

  def test_query_like_nomatch
    struct = ::Service::City::Search.new(
      query: "name:~ny",
      offset: 0,
      limit: 10,
    ).call

    assert_equal 0, struct.code
    assert_equal 0, struct.cities.length
    assert_equal 0, struct.total
  end
end