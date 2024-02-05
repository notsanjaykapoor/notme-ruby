ENV["RACK_ENV"] = "tst"

require "minitest/reporters"

require "./boot"

Minitest::Reporters.use! [ Minitest::Reporters::SpecReporter.new ]