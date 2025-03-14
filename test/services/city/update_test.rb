require "minitest/autorun"
require "test_helper"

class CityUpdateTest < Minitest::Test
  def teardown
    ::Model::City.truncate
  end

  def test_create
    data = {
      "place_id" => 26279198,
      "licence" => "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
      "osm_type" => "relation",
      "osm_id" => 122604,
      "lat" => "41.8755616",
      "lon" => "-87.6244212",
      "class" => "boundary",
      "type" => "administrative",
      "place_rank" => 16,
      "importance" => 0.7515295727100249,
      "addresstype" => "city",
      "name" => "Chicago",
      "display_name" => "Chicago, Cook County, Illinois, United States",
      "address" => {
        "city"=>"Chicago",
        "county"=>"Cook County",
        "state"=>"Illinois",
        "ISO3166-2-lvl4"=>"US-IL",
        "country"=>"United States",
        "country_code"=>"us"
      },
      "boundingbox" => ["41.6445310", "42.0230396", "-87.9400876", "-87.5240812"]
    }

    update_result = ::Service::City::Update.new(data: data).call

    assert_equal update_result.code, 0

    city = ::Model::City.find(id: update_result.city.id)

    assert_equal city.bbox, [41.644531, 42.023040, -87.940088, -87.524081] # 6 digits
    assert_equal city.country_code, "US"
    assert_equal city.lat, 41.875562 # 6 digits
    assert_equal city.lon, -87.624421 # 6 digits
    assert_equal city.name, "Chicago"
  end

end