require "minitest/autorun"
require "test_helper"

class PlaceTest < Minitest::Test
  def teardown
    ::Model::Place.truncate
  end

  def test_name_and_source_unique
    place_1 = ::Model::Place.create(
      city: "Chicago", 
      geo_json: {},
      name: "Chicago Place",
      lat: 42.35,
      lon: -71.05,
      source_id: ULID.generate,
      source_name: "mapbox",
      tags: ["food"],
    )
    assert place_1.id
    assert_equal place_1.city, "Chicago"
    assert_equal place_1.geo_json, {}
    assert_equal place_1.lat, 42.35
    assert_equal place_1.lon, -71.05
    assert_equal place_1.name, "Chicago Place"
    assert place_1.source_id
    assert_equal place_1.tags, ["food"]

    place_2 = ::Model::Place.create(
      city: "Boston",
      geo_json: {},
      name: "Boston Place",
      lat: 42.35,
      lon: -71.05,
      source_id: ULID.generate,
      source_name: "mapbox,"
    )
    assert place_2.id

    assert_raises Sequel::ValidationFailed do
      ::Model::Place.create(
        city: "Chicago",
        geo_json: {},
        name: "Chicago Place",
        lat: 42.35,
        lon: -71.05,
        source_id: ULID.generate,
        source_name: "mapbox,"
      )
    end

    assert_raises Sequel::UniqueConstraintViolation do
      ::Model::Place.create(
        city: "Atlanta",
        geo_json: {},
        name: "Atlanta Place",
        lat: 42.35,
        lon: -71.05,
        source_id: place_1.source_id,
        source_name: "mapbox",
      )
    end
  end

end