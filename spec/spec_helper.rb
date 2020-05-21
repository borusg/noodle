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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
  def self.node_funkymonkey_jupiter
    {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        funkymonkey:     :town,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
      }
    }.to_json
  end
  def self.node_jupiter(magnitude: nil)
    node = {
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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
      params: {
        created_by:      :spec,
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

describe 'Noodle' do
  it "should allow refreshing options" do
    ## Allow gum to be a hash
    # Create ilk=option entry and refresh options:
    noodlin = 'create -i option -p noodle -P prod -s mars -a target_ilk=default -a limits.limits=hash default.option.example.com'
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    noodlin = 'param limits.project=hr,financials,lms,noodle,registration,test,warehouse default.option.example.com'
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    # Let limits.gum be a hash,
    noodlin = 'param limits.gum=hash default.option.example.com'
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}
    # Let limits.chew be a hash too
    noodlin = 'param limits.chew=hash default.option.example.com'
    assert_output("\n"){puts %x{bin/noodlin #{noodlin}}}

    # Refresh options
    assert_output("Your options had a nap and they are nicely refreshed.\n"){puts %x{bin/noodlin optionrefresh}}

    put '/nodes/zippyziggy.example.com', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status
  end
end
