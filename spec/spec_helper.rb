require 'coveralls'
Coveralls.wear!

ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require_relative '../noodle'

# Make sure we don't explode a real index
Node.gateway.index = 'this-is-for-running-noodle-elasticsearch-tests-only'
# TODO: What's the right way to do this?
begin
    Node.gateway.delete_index!
rescue
end

# TODO: Enable this via 'rake debug' or something
# Holy cow, log
#Node.gateway.client.transport.logger = Logger.new(STDERR)

# Make sure the index exists
Node.gateway.create_index!

require 'minitest/reporters'
Minitest::Reporters.use!

include Rack::Test::Methods

def app
  Noodle
end

