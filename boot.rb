require "async"
require "graphql"
require "oj"
require "process/metrics"
require "roda"
require "sequel"
require "toml-rb"

Console.logger.info("Boot", "starting")

::Sequel.extension(:fiber_concurrency, :pg_array_ops, :pg_json_ops)

require "./boot/database.rb"
require "./boot/json.rb"
require "./boot/secret.rb"

Boot::Secret.new.call

struct_boot_database = Boot::Database.new.call

Boot::Json.new.call

# initialize db global object

DB = struct_boot_database.connection
DB.extension(:pg_array, :pg_json)

Console.logger.info("Boot", "database connection initialized")

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
