require 'coveralls'
Coveralls.wear!

ENV['RACK_ENV'] = 'test'
require 'rack/test'
require_relative '../lib/noodle'
require 'securerandom'

ENV['NOODLE_SERVER'] = 'localhost:2929'

# Make sure we don't explode a real index
Noodle::Node.gateway.index = 'this-is-for-running-noodle-elasticsearch-tests-only'
# TODO: What's the right way to do this?
begin
  Noodle::Node.gateway.delete_index!
rescue
end

# TODO: Enable this via 'rake debug' or something
# Holy cow, log
#Noodle::Node.gateway.client.transport.logger = Logger.new(STDERR)

# Make sure the index exists
Noodle::Node.gateway.create_index!
Noodle::Node.gateway.refresh_index!

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!

include Rack::Test::Methods

module HappyHelper
  def self.randomhostname
    SecureRandom.uuid.gsub('-','') + '.example.com'
  end
end

# Minitest
def app
  Noodle
end

# Start a local rack server to serve up test pages.
@server_thread = Thread.new do
  Noodle::Node.gateway.index = 'this-is-for-running-noodle-elasticsearch-tests-only'
  Rack::Handler::Thin.run Noodle.new, :Port => 2929
end
sleep(1) # wait a sec for the server to be booted
