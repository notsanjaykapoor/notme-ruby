require "async"
require "base58"
require "dotenv"
require "geocoder"
require "graphql"
require "oj"
require "openssl"
require "opentelemetry-exporter-otlp"
require "opentelemetry/instrumentation/all"
require "opentelemetry/sdk"
require "roda"
require "sequel"
require "ulid"

Console.logger.info("Boot", "starting")

::Sequel.extension(:fiber_concurrency, :pg_array_ops, :pg_json_ops)
::Sequel.datetime_class = Time
::Sequel.default_timezone = :utc

require "./boot/database.rb"
require "./boot/geo.rb"
require "./boot/json.rb"
require "./boot/opentel.rb"
require "./boot/secret.rb"

Boot::Secret.new.call

if ENV["RACK_ENV"] in ["dev", "tst"]
  require "debug"
end

boot_database = Boot::Database.new.call

Boot::Json.new.call

# initialize db global object

DB = boot_database.connection
DB.extension(:pg_array, :pg_json)

Console.logger.info("Boot", "database connection initialized")

# initialize opentelemetry

boot_opentel = Boot::OpenTel.new.call

if boot_opentel.code == 0
  AppTracer = boot_opentel.tracer
end

# initialize geocoder

boot_geo = Boot::Geo.new.call

Console.logger.info("Boot", "geo initialized - #{boot_geo.name}")

# load app files

app_files = Dir["./app/**/*.rb"].sort
gql_files = Dir["./app/gql/**/*.rb"].sort

(app_files - gql_files).each do |file|
  require file
end

# load graphql files, load order matters here:
# 1. gql_objects
# 2. gql_responses
# 3. base gql files

Dir["./app/gql/gql_objects/**/*.rb"].sort.each do |file|
  require file
end

Dir["./app/gql/gql_responses/**/*.rb"].sort.each do |file|
  require file
end

Dir["./app/gql/*.rb"].sort.each do |file|
  require file
end

Console.logger.info("Boot", "app files loaded")

Console.logger.info("Boot", "completed")
