require "minitest/autorun"
require "test_helper"

class PlacesCreateTest < Minitest::Test
  def teardown
    ::Model::Place.truncate
  end

  def test_create
    geo_json = {
      "type"=>"FeatureCollection",
      "features" => [
        {
          "type" => "Feature",
          "geometry" => {
            "coordinates"=>[-87.631073, 41.891392],
            "type"=>"Point",
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
              "latitude"=>41.891392,
              "longitude"=>-87.631073,
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
      geo_json: geo_json,
    ).call

    assert struct.code == 0
    assert struct.places.length == 1

    place = struct.places[0]

    assert place.id
    assert place.city == "Chicago"
    assert place.lat == 41.891392
    assert place.lon == -87.631073
    assert place.source_id == "dXJuOm1ieHBvaTo0NWZiZWE3Yi1hYTI3LTQ0NmItOTJlOC03MTlhYjliYmVhMTc"
    assert place.source_name = "mapbox"
  end

end