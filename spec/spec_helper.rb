require 'coveralls'
Coveralls.wear!

ENV['RACK_ENV'] = 'test'
require 'rack/test'
require_relative '../lib/noodle'
require 'securerandom'

ENV['NOODLE_SERVER'] = 'localhost:2929'

# TODO: Enable this via 'rake debug' or something
# Holy cow, log
#Noodle::Node.gateway.client.transport.logger = Logger.new(STDERR)

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
  Rack::Handler::Thin.run Noodle.new, :Port => 2929
end

# 3/14/2017: Ran all tests 3 times without this and only once did a single test fail:
# sleep(1) # wait a sec for the server to be booted
# So, um, I'll leave it out for a while.
# 4/16/2017: Welp, today tests fail without this sleep :(
# One day I'll track it down!
# 12/13/2019: Still trouble with out this sleep
sleep 1
