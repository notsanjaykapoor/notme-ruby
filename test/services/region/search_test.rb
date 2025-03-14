require "minitest/autorun"
require "test_helper"

class RegionSearchTest < Minitest::Test
  def setup
    @france = ::Model::Region.create(code: "FR", data: {}, name: "France", lat: 46.603354, lon: 1.8883335, type: "country")
    @europe = ::Model::Region.create(code: "US", data: {}, name: "Europe", lat: 51.0, lon: 10.0, type: "continent")
  end

  def teardown
    ::Model::Region.truncate
  end

  def test_query_all
    struct = ::Service::Region::Search.new(
      query: "",
      offset: 0,
      limit: 10,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.regions.length, 2
    assert_equal struct.total, 2
  end

  def test_query_id_match
    struct = ::Service::Region::Search.new(
      query: "id:#{@europe.id}",
      offset: 0,
      limit: 1,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.regions.length, 1
    assert_equal struct.regions[0].name, "Europe"
    assert_equal struct.total, 1
  end

  def test_query_like_match
    struct = ::Service::Region::Search.new(
      query: "name:~fra",
      offset: 0,
      limit: 10,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.regions.length, 1
  end

  def test_query_like_nomatch
    struct = ::Service::Region::Search.new(
      query: "name:~xxx",
      offset: 0,
      limit: 10,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.regions.length, 0
    assert_equal struct.total, 0
  end
end