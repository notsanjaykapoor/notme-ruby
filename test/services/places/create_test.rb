require "minitest/autorun"
require "test_helper"

class PlacesCreateTest < Minitest::Test
  def setup
    @chicago = ::Model::City.create(country_code: "US", data: {}, name: "Chicago", lat: 41.85, lon: -87.65)
  end

  def teardown
    ::Model::Place.truncate
    ::Model::City.truncate
  end

  def test_create_with_valid_feature
    geo_json = {
      "type"=>"FeatureCollection",
      "features" => [
        {
          "type" => "Feature", # required
          "geometry" => {
            "coordinates"=>[-87.631073, 41.891392], # required
            "type"=>"Point", # required
          },
          "properties" => {
            "name"=>"Beatrix River North",
            "mapbox_id"=>"dXJuOm1ieHBvaTo0NWZiZWE3Yi1hYTI3LTQ0NmItOTJlOC03MTlhYjliYmVhMTc",
            "feature_type"=>"poi",
            "address"=>"519 N Clark St",
            "full_address"=>"519 N Clark St, Chicago, Illinois 60654, United States",
            "place_formatted"=>"Chicago, Illinois 60654, United States",
            "context"=>{
              "country"=>{"id"=>"", "name"=>"United States", "country_code"=>"US", "country_code_alpha_3"=>"USA"},
              "region"=>{"id"=>"", "name"=>"Illinois", "region_code"=>"IL", "region_code_full"=>"US-IL"},
              "postcode"=>{"id"=>"dXJuOm1ieHBsYzpER3VPN0E", "name"=>"60654"},
              "place"=>{"id"=>"dXJuOm1ieHBsYzpBNGxJN0E", "name"=>"Chicago"},
              "neighborhood"=>{"id"=>"dXJuOm1ieHBsYzpJRENNN0E", "name"=>"River North"},
              "address"=>{"id"=>"", "name"=>"519 N Clark St", "address_number"=>"519", "street_name"=>"n clark st"},
              "street"=>{"id"=>"", "name"=>"n clark st"}
            },
            "coordinates"=>{
              "latitude"=>41.891392, # optional
              "longitude"=>-87.631073, # optional
              "routable_points"=>[{"name"=>"default", "latitude"=>41.891390910897094, "longitude"=>-87.63112154287269}]
            },
            "language"=>"en",
            "maki"=>"restaurant",
            "poi_category"=>["american restaurant", "brunch restaurant", "food", "food and drink", "restaurant"],
            "poi_category_ids"=>["american_restaurant", "brunch_restaurant", "food", "food_and_drink", "restaurant"],
            "external_ids"=>{"foursquare"=>"51b0b828498ecb8d51e396ea", "safegraph"=>"223-222@5pw-624-ct9"},
          }
        }
      ]
    }

    struct = ::Service::Places::Create.new(
      city: @chicago,
      geo_json: geo_json,
      source_name: ::Model::Place::SOURCE_MAPBOX,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.places.length, 1

    place = struct.places[0]

    assert_operator place.id, :>, 0
    assert_equal place.city, "Chicago"
    assert_equal place.country_code, "US"
    assert_equal place.lat, 41.891392
    assert_equal place.lon, -87.631073
    assert_equal place.mappable, 1
    assert_equal place.source_id, "dXJuOm1ieHBvaTo0NWZiZWE3Yi1hYTI3LTQ0NmItOTJlOC03MTlhYjliYmVhMTc"
    assert_equal place.source_name, "mapbox"
    assert_equal place.tags, ["bar", "food"]
  end

  def test_create_with_invalid_type
    geo_json = {
      "type"=>"FeatureCollection",
      "features" => [
        {
          "type" => "Invalid",
        }
      ]
    }

    struct = ::Service::Places::Create.new(
      city: @chicago,
      geo_json: geo_json,
      source_name: ::Model::Place::SOURCE_MAPBOX,
    ).call

    assert struct.code == 422
    assert struct.places.length == 0

    geo_json = {
      "type"=>"InvalidCollection",
      "features" => [
        {
          "type" => "Feature",
        }
      ]
    }

    struct = ::Service::Places::Create.new(
      city: @chicago,
      geo_json: geo_json,
      source_name: ::Model::Place::SOURCE_MAPBOX,
    ).call

    assert_equal struct.code, 422
    assert_equal struct.places.length, 0
  end

  def test_create_with_manual_input
    struct = ::Service::Places::CreateFromManual.new(
      name: "Place 1",
      city: @chicago,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.places.length, 1

    place = struct.places[0]

    assert_operator place.id, :>, 0
    assert_equal place.city, "Chicago"
    assert_equal place.country_code, "US"
    assert_equal place.lat, @chicago.lat
    assert_equal place.lon, @chicago.lon
    assert_equal place.mappable, 1
    assert_equal place.name, "Place 1"
    assert_equal place.source_name, "manual"
  end

end