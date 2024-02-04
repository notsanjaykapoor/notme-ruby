require "minitest/autorun"
require "test_helper"

class WeatherSearchTest < Minitest::Test
  def setup
    ::Model::Weather.create(data: {}, name: "Boston", lat: 42.35, lon: -71.05, temp: 30.00)
    ::Model::Weather.create(data: {}, name: "Chicago", lat: 41.85, lon: -87.65, temp: 35.00)
  end

  def teardown
    ::Model::Weather.truncate
  end

  def test_query_all
    struct = ::Service::Weather::Search.new(
      query: "",
      offset: 0,
      limit: 10,
    ).call

    assert struct.code == 0
    assert struct.objects.length == 2
  end

  def test_query_like_match
    struct = ::Service::Weather::Search.new(
      query: "name:~chi",
      offset: 0,
      limit: 10,
    ).call

    assert struct.code == 0
    assert struct.objects.length == 1
  end

  def test_query_like_nomatch
    struct = ::Service::Weather::Search.new(
      query: "name:~ny",
      offset: 0,
      limit: 10,
    ).call

    assert struct.code == 0
    assert struct.objects.length == 0
  end
end