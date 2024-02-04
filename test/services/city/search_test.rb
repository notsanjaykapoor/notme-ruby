require "minitest/autorun"
require "test_helper"

class CitySearchTest < Minitest::Test
  def setup
    @city = ::Model::City.create(data: {}, name: "Boston", lat: 42.35, lon: -71.05)
    @city = ::Model::City.create(data: {}, name: "Chicago", lat: 41.85, lon: -87.65)
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

    assert struct.code == 0
    assert struct.cities.length == 2
  end

  def test_query_like_match
    struct = ::Service::City::Search.new(
      query: "name:~chi",
      offset: 0,
      limit: 10,
    ).call

    assert struct.code == 0
    assert struct.cities.length == 1
  end

  def test_query_like_nomatch
    struct = ::Service::City::Search.new(
      query: "name:~ny",
      offset: 0,
      limit: 10,
    ).call

    assert struct.code == 0
    assert struct.cities.length == 0
  end
end