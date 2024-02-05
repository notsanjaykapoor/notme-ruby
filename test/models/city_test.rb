require "minitest/autorun"
require "test_helper"

class CityTest < Minitest::Test
  def teardown
    ::Model::City.truncate
  end

  def test_name_unique
    city_1 = ::Model::City.create(data: {}, name: "Chicago", lat: 42.35, lon: -71.05)
    assert city_1.id
    assert_equal city_1.lat, 42.35
    assert_equal city_1.lon, -71.05
    assert_equal city_1.name, "Chicago"

    assert_raises Sequel::ValidationFailed do
      ::Model::City.create(data: {}, name: "Chicago", lat: 42.35, lon: -71.05)
    end

    city_2 = ::Model::City.create(data: {}, name: "Boston", lat: 42.35, lon: -71.05)
    assert city_2.id
  end

end