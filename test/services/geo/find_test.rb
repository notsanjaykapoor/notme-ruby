require "minitest/autorun"
require "test_helper"

class GeoFindTest < Minitest::Test

  def setup
    @chicago = ::Model::City.create(country_code: "US", data: {}, name: "Chicago", lat: 41.85, lon: -87.65)
    @france = ::Model::Region.create(code: "FR", data: {}, name: "France", lat: 46.603354, lon: 1.8883335, type: "country")
  end

  def teardown
    ::Model::City.truncate
    ::Model::Region.truncate
  end

  def test_find_city_match
    find_result = ::Service::Geo::Find.new(query: "chicago").call

    assert_equal 0, find_result.code
    assert_equal @chicago.id, find_result.box.id
    assert_equal "Chicago", find_result.box.name
  end

  def test_find_region_match
    find_result = ::Service::Geo::Find.new(query: "france").call

    assert_equal 0, find_result.code
    assert_equal @france.id, find_result.box.id
    assert_equal "France", find_result.box.name
  end

  def test_find_no_match
    find_result = ::Service::Geo::Find.new(query: "xxx").call

    assert_equal 404, find_result.code
    assert_equal nil, find_result.box
  end

end