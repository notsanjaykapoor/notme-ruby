require "rake/testtask"

system("RACK_ENV=tst ./bin/db-migrate")

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/models/**_test.rb", "test/services/*/**_test.rb", "test/app/**_test.rb"]
  t.verbose = true
end