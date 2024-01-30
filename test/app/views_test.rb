require "minitest/autorun"
require "test_helper"
require "rack"
require "rack/test"

class WeatherApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @app ||= Rack::Builder.parse_file("config.api.ru")
  end

  def test_root
    get "/"
    assert last_response.status == 302
  end

  def test_weather
    get "/weather"
    assert last_response.status == 200
  end
end
