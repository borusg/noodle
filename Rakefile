# Rubocop says:
# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rake/testtask'

task default: [:test]

task :test_authttps do
  ENV['APP_ENV'] = 'test_authttps'
end

task :test_authttps_localhost do
  ENV['APP_ENV'] = 'test_authttps_localhost'
end

Rake::TestTask.new(:test) do |t|
  t.pattern = 'spec/*.rb'
end

Rake::TestTask.new(:test_authttps) do |t|
  t.pattern = 'spec/*.rb'
end

Rake::TestTask.new(:test_authttps_localhost) do |t|
  t.pattern = 'spec/*.rb'
end
