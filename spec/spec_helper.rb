require 'coveralls'
Coveralls.wear!

ENV['RACK_ENV'] = 'test'
require 'rack/test'
require_relative '../lib/noodle'
require 'securerandom'
require 'rack/handler/puma'

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
    SecureRandom.alphanumeric(15) + '.example.com'
  end

  def self.node_mars
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :surplus,
        site:            :mars,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_moon
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :surplus,
        site:            :moon,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_piggly
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :surplus,
        site:            :moon,
        project:         :pigglywiggly,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_funky_jupiter
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        funky:           :town,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_jupiter(magnitude: nil)
    node = {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        justfora:        :test,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }
    node[:facts] = {magnitude: magnitude} unless magnitude.nil?
    node.to_json
  end
  def self.node_prod_jupiter
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        justfora:        :test,
        project:         :hr,
        prodlevel:       :prod,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_jupiter_json
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        output:          :json,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_jupiter_full
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        full:            :yes,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_uranus
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :uranus,
        justfora:        :test,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_pluto
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :pluto,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_prod_pluto
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :pluto,
        project:         :hr,
        prodlevel:       :prod,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_neptune
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :neptune,
        justfora:        :test,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_prod_neptune
    {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :neptune,
        justfora:        :test,
        project:         :hr,
        prodlevel:       :prod,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_saturn(magnitude: nil)
    node = {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :saturn,
        magic_dne:       :yes,
        at_me:           :yes,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }
    node[:facts] = {magnitude: magnitude} unless magnitude.nil?
    node.to_json
  end
  def self.node_venus(magnitude: nil)
    node = {
      created_by: 'spec',
      params: {
        ilk:             :host,
        status:          :enabled,
        site:            :venus,
        magic_dne:       :yes,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }
    node[:facts] = {magnitude: magnitude} unless magnitude.nil?
    node.to_json
  end

#  def self.node_funky_jupiter
#    {
#      created_by: 'spec',
#      params: {
#        ilk:             :host,
#
#        last_updated_by: :spec,
#      }
#    }.to_json
#  end

end

# Minitest
def app
  Noodle
end

# Start a local rack server to serve up test pages.
@server_thread = Thread.new do
  Rack::Handler::Puma.run Noodle.new, :Port => 2929
end

# 3/14/2017: Ran all tests 3 times without this and only once did a single test fail:
# sleep(1) # wait a sec for the server to be booted
# So, um, I'll leave it out for a while.
# 4/16/2017: Welp, today tests fail without this sleep :(
# One day I'll track it down!
# 12/13/2019: Still trouble with out this sleep
sleep 1
