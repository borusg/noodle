require 'rspec/core/rake_task'

task default: [:test]

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.pattern = 'spec/*.rb'
end

Rake::TestTask.new(:pigs) do |t|
  ENV['APP_ENV'] = 'test_authttps'
  t.pattern = 'spec/*.rb'
end
