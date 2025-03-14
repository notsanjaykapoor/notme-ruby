require "minitest/autorun"
require "test_helper"

class RegionUpdateTest < Minitest::Test

  def teardown
    ::Model::Region.truncate
  end

  def test_create_continent
    data = {
      "place_id" => 26279198,
      "licence" => "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
      "osm_type" => "relation",
      "osm_id" => 1250222,
      "lat" => "51.0",
      "lon" => "10.0",
      "class" => "place",
      "type" => "administrative",
      "place_rank" => 16,
      "importance" => 0.7515295727100249,
      "addresstype" => "continent",
      "name" => "Europe",
      "display_name" => "Europe",
      "address" => {"continent" => "Europe"},
      "boundingbox" => ["26.0000000", "76.0000000", "-15.0000000", "35.0000000"],
    }

    update_result = ::Service::Region::Update.new(data: data).call

    assert_equal update_result.code, 0

    region = ::Model::Region.find(id: update_result.region.id)

    assert_equal region.bbox, [26.000000, 76.000000, -15.000000, 35.000000] # 6 digits
    assert_equal region.code, ""
    assert_equal region.lat, 51.0 # 6 digits
    assert_equal region.lon, 10.0 # 6 digits
    assert_equal region.name, "Europe"
    assert_equal region.type, "continent"
  end

  def test_create_country
    data = {
      "place_id" => 26279198,
      "licence" => "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
      "osm_type" => "relation",
      "osm_id" => 1250222,
      "lat" => "46.603354",
      "lon" => "1.8883335",
      "class" => "boundary",
      "type" => "administrative",
      "place_rank" => 16,
      "importance" => 0.7515295727100249,
      "addresstype" => "country",
      "name" => "France",
      "display_name" => "France",
      "address" => {"country" => "France", "country_code" => "fr"},
      "boundingbox" => ["-50.2187169", "51.3055721", "-178.3873749", "172.3057152"],
    }

    update_result = ::Service::Region::Update.new(data: data).call

    assert_equal update_result.code, 0

    region = ::Model::Region.find(id: update_result.region.id)

    assert_equal region.bbox, [-50.218717, 51.305572, -178.387375, 172.305715] # 6 digits
    assert_equal region.code, "FR"
    assert_equal region.lat, 46.603354 # 6 digits
    assert_equal region.lon, 1.888334 # 6 digits
    assert_equal region.name, "France"
    assert_equal region.type, "country"
  end

end