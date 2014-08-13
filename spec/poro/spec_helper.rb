ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../noodle'

require "minitest/reporters"
Minitest::Reporters.use!

include Rack::Test::Methods

def app
  Noodle
end

