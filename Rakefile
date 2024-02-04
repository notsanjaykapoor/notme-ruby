require "rake/testtask"

system("RACK_ENV=tst ./bin/db-migrate")

Rake::TestTask.new("test") do |t|
  t.libs << "test"
  t.test_files = FileList["test/models/**_test.rb", "test/services/*/**_test.rb", "test/app/**_test.rb"]
  t.verbose = true
end

Rake::TestTask.new("test-all") do |t|
  Rake::Task["test"].execute
end

Rake::TestTask.new("test-app") do |t|
  t.libs << "test"
  t.test_files = FileList["test/app/**_test.rb"]
  t.verbose = true
end

Rake::TestTask.new("test-models") do |t|
  t.libs << "test"
  t.test_files = FileList["test/models/**_test.rb"]
  t.verbose = true
end

Rake::TestTask.new("test-services") do |t|
  t.libs << "test"
  t.test_files = FileList["test/services/*/**_test.rb"]
  t.verbose = true
end