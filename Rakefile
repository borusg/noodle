require 'rspec/core/rake_task'

task :default => [:spec]

desc "Run the tests"
RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = '--color -f documentation'
    t.pattern    = 'spec/*.rb'
end

