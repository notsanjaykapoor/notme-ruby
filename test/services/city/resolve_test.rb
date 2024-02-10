require "minitest/autorun"
require "test_helper"

class CityResolveTest < Minitest::Test
  def setup
    ::Model::City.create(data: {}, name: "Chicago", lat: 41.85, lon: -87.65)
  end

  def teardown
    ::Model::City.truncate
  end

  def test_resolve_with_city_already_exists
    resolve_result = ::Service::City::Resolve.new(
      query: "name:~chicago",
      offset: 0,
      limit: 10,
    ).call

    # should return existing city
    assert_equal 0, resolve_result.code
    assert_equal "Chicago", resolve_result.city.name
  end

  def test_resolve_with_city_not_exists
    resolve_result = ::Service::City::Resolve.new(
      query: "name:~munich",
      offset: 0,
      limit: 10,
    ).call

    binding.break #

    # should create city
    assert_equal 0, resolve_result.code
    assert_equal "Munich", resolve_result.city.name
  end

end