require "minitest/autorun"
require "test_helper"

class CityResolveTest < Minitest::Test
  def setup
    @chicago = ::Model::City.create(data: {}, name: "Chicago", lat: 41.85, lon: -87.65)
  end

  def teardown
    ::Model::City.truncate
  end

  def test_resolve_with_city_already_exists
    assert_equal 1, ::Model::City.count

    # query with explicit name tag
    resolve_result = ::Service::City::Resolve.new(
      query: "name:~chicago",
      offset: 0,
      limit: 10,
    ).call

    assert_equal 1, ::Model::City.count

    # should return existing city
    assert_equal 0, resolve_result.code
    assert_equal "Chicago", resolve_result.city.name

    # query with explicit id tag
    resolve_result = ::Service::City::Resolve.new(
      query: "id:#{@chicago.id}",
      offset: 0,
      limit: 1,
    ).call

    assert_equal 1, ::Model::City.count

    # should return existing city
    assert_equal 0, resolve_result.code
    assert_equal "Chicago", resolve_result.city.name

    # query with implicit name tag
    resolve_result = ::Service::City::Resolve.new(
      query: "chicago",
      offset: 0,
      limit: 1,
    ).call

    assert_equal 1, ::Model::City.count

    # should return existing city
    assert_equal 0, resolve_result.code
    assert_equal "Chicago", resolve_result.city.name

    # query with implicit id tag
    resolve_result = ::Service::City::Resolve.new(
      query: "#{@chicago.id}",
      offset: 0,
      limit: 1,
    ).call

    assert_equal 1, ::Model::City.count

    # should return existing city
    assert_equal 0, resolve_result.code
    assert_equal "Chicago", resolve_result.city.name
  end

  def test_resolve_with_city_not_exists
    assert_equal 1, ::Model::City.count

    resolve_result = ::Service::City::Resolve.new(
      query: "name:~munich",
      offset: 0,
      limit: 1,
    ).call

    assert_equal 2, ::Model::City.count

    # should create city
    assert_equal 0, resolve_result.code
    assert_equal "Munich", resolve_result.city.name
  end

end