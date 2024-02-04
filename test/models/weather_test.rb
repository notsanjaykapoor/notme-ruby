require "minitest/autorun"
require "test_helper"

class WeatherTest < Minitest::Test
  def teardown
    ::Model::Weather.truncate
  end

  def test_name_unique
    w_1 = ::Model::Weather.create(data: {}, name: "Chicago", lat: 42.35, lon: -71.05, temp: 30.00)
    assert w_1.id
    assert w_1.name == "Chicago"

    assert_raises Sequel::ValidationFailed do
      ::Model::Weather.create(data: {}, name: "Chicago", lat: 42.35, lon: -71.05, temp: 30.00)
    end

    w_2 = ::Model::Weather.create(data: {}, name: "Boston", lat: 42.35, lon: -71.05, temp: 30.00)
    assert w_2.id
  end

end