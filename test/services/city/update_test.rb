require "minitest/autorun"
require "test_helper"

class CityUpdateTest < Minitest::Test
  def teardown
    ::Model::City.truncate
  end

  def test_create
    data = {
      "type" => "Feature",
      "properties" => {
        "city" => "Chicago",
        "county" => "Cook County",
        "country" => "United States",
        "country_code" => "us",
        "name" => "Chicago",
        "place_id" => 26279198,
        "result_type" => "city",
        "state" => "Illinois",
        "state_code" => "IL",
      },
      "geometry" => {
        "type" => "Point", "coordinates" => [-87.6244212, 41.8755616]
      },
      "bbox" => [-87.9400876, 41.644531, -87.5240812, 42.0230396],
    }

    update_result = ::Service::City::Update.new(name: "Chicago", geo_json: data).call

    assert_equal update_result.code, 0

    city = ::Model::City.find(id: update_result.city.id)

    assert_equal city.bbox, [-87.940088, 41.644531, -87.524081, 42.023040] # 6 digits
    assert_equal city.country_code, "US"
    assert_equal city.data.fetch("type"), "Feature"
    assert_equal city.lat, 41.875562 # 6 digits
    assert_equal city.lon, -87.624421 # 6 digits
    assert_equal city.name, "Chicago"
  end

end