require "minitest/autorun"
require "test_helper"

class PlaceSearchTest < Minitest::Test
  def setup
    @city_chicago = ::Model::City.create(
      bbox: [41.644531,42.023040,-87.940088,-87.524081],
      data: {},
      name: "Chicago",
      lat: 41.875562,
      lon: -87.624421,
    )

    ::Model::Place.create(
      city: "Chicago", 
      geo_json: {},
      name: "Chicago Place",
      lat: 41.918353,
      lon: -87.653600,
      source_id: ULID.generate,
      source_name: ::Model::Place::SOURCE_MAPBOX,
      tags: ["food"],
    )

    ::Model::Place.create(
      city: "Burb", 
      geo_json: {},
      name: "Not Chicago Place",
      lat: 41.533333, # outside chicago bounding box
      lon: -87.653600,
      source_id: ULID.generate,
      source_name: ::Model::Place::SOURCE_MAPBOX,
      tags: ["food"],
    )
  end

  def teardown
    ::Model::Place.truncate
    ::Model::City.truncate
  end

  def test_query_all
    struct = ::Service::Places::Search.new(
      query: "",
      offset: 0,
      limit: 10,
    ).call

    assert_equal struct.code, 0
    assert_equal struct.places.length, 2
  end

  def test_query_city_id_match
    struct = ::Service::Places::Search.new(
      query: "city:#{@city_chicago.id}",
      offset: 0,
      limit: 10,
    ).call

    assert_equal 0, struct.code
    assert_equal 1, struct.places.length
  end

  def test_query_city_like_match
    struct = ::Service::Places::Search.new(
      query: "city:~chi",
      offset: 0,
      limit: 10,
    ).call

    assert_equal 0, struct.code
    assert_equal 1, struct.places.length
  end

  def test_query_city_like_nomatch
    struct = ::Service::Places::Search.new(
      query: "city:~bos",
      offset: 0,
      limit: 10,
    ).call

    assert_equal 0, struct.code
    assert_equal 0, struct.places.length
  end

  def test_query_city_near_match
    struct = ::Service::Places::Search.new(
      query: "near:chicago",
      offset: 0,
      limit: 10,
    ).call

    # should return 1 place within city bounds
    assert_equal 0, struct.code
    assert_equal 1, struct.places.length
  end

  def test_query_city_near_invalid
    struct = ::Service::Places::Search.new(
      query: "near:unknown",
      offset: 0,
      limit: 10,
    ).call

    # should return no places
    assert_equal 422, struct.code
    assert_equal 0, struct.places.length
  end

  def test_query_name_prefix_match
    struct = ::Service::Places::Search.new(
      query: "name:chi",
      offset: 0,
      limit: 10,
    ).call

    assert_equal 0, struct.code
    assert_equal 1, struct.places.length
  end

  def test_query_field_invalid
    struct = ::Service::Places::Search.new(
      query: "xxx:chi",
      offset: 0,
      limit: 10,
    ).call

    # should return no places
    assert_equal 422, struct.code
    assert_equal 0, struct.places.length
  end

end