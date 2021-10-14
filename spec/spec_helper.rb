# Rubocop says:
# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

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
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new]

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
        last_updated_by: :spec
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
        color:           :purple,
        last_updated_by: :spec
      },
      facts: {
        thatsa: 'jack'
      }
    }.to_json
  end
  def self.node_moon_sslcert
    {
      params: {
        created_by:      :spec,
        ilk:             :esx,
        status:          :surplus,
        site:            :moon,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
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
        last_updated_by: :spec
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
        role:            %w[pigs fly],
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
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
        funky:           :town,
        funkymonkey:     :town,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
      }
    }.to_json
  end
  def self.node_funky_jupiter_dnex
    {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        funky:           :town,
        dnex:            :yep,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
      }
    }.to_json
  end
  def self.node_funkymonkey_jupiter_dnex
    {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        funky:           :town,
        dnex:            :yep,
        funkymonkey:     :town,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
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
        last_updated_by: :spec
      }
    }
    node[:facts] = { magnitude: magnitude } unless magnitude.nil?
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
        last_updated_by: :spec
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
        last_updated_by: :spec
      }
    }.to_json
  end
  def self.node_jupiter_json2
    {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :enabled,
        site:            :jupiter,
        output:          :json2,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
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
        last_updated_by: :spec
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
        last_updated_by: :spec
      }
    }.to_json
  end
  def self.node_hashdig
    {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :enabled,
        site:            :pluto,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
        hashdig:         :yep,
        gum: {
          address: {
            zipcode: 90_210
          }
        }
      },
      facts: {
        fqdn: 'hashdig-node-with-hash.example.com',
        chew: {
          carrots: {
            times: 12
          }
        }
      }
    }.to_json
  end
  def self.node_hashdig_without_hash
    {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :enabled,
        site:            :pluto,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec,
        hashdig:         :yep
      },
      facts: {
        fqdn: 'hashdig-node-without-hash.example.com',
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
        last_updated_by: :spec
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
        last_updated_by: :spec
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
        last_updated_by: :spec
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
        last_updated_by: :spec
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
        magic_dneq:      :yes,
        at_me:           :yes,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
      }
    }
    node[:facts] = { magnitude: magnitude } unless magnitude.nil?
    node.to_json
  end
  def self.node_venus(magnitude: nil)
    node = {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :enabled,
        site:            :venus,
        magic_dneq:      :yes,
        project:         :hr,
        prodlevel:       :dev,
        last_updated_by: :spec
      }
    }
    node[:facts] = { magnitude: magnitude } unless magnitude.nil?
    node.to_json
  end
  def self.node_hashy
    {
      params: {
        created_by:      :spec,
        ilk:             :host,
        status:          :surplus,
        site:            :moon,
        project:         :hr,
        prodlevel:       :dev,
        color:           :purple,
        last_updated_by: :spec
      },
      facts: {
        this: {
          is: {
            a: {
              very: 'berry',
              nested: {
                hash: {
                  value: 4
                }
              }
            }
          },
          isnt: {
            as: 'nested'
          }
        }
      }
    }.to_json
  end


end

# Minitest
def app
  Noodle
end

# Start a local rack server to serve up test pages.
@server_thread = Thread.new do
  Rack::Handler::Puma.run Noodle.new, Port: 2929
end

describe 'Noodle' do
  it "allow refreshing options" do
    ## Allow gum to be a hash
    # Create ilk=option entry and refresh options:
    noodlin = 'create -i option -p noodle -P prod -s mars -a target_ilk=default -a limits.limits=hash default.option.example.com -w test'
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    noodlin = 'param limits.project=hr,financials,lms,noodle,registration,test,warehouse default.option.example.com -w test'
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Let limits.gum be a hash,
    noodlin = 'param limits.gum=hash default.option.example.com -w test'
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }
    # Let limits.chew be a hash too
    noodlin = 'param limits.chew=hash default.option.example.com -w test'
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Uniqueness based on name *and* ilk:
    noodlin = 'param limits.uniqueness_params=array default.option.example.com -w test'
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }
    noodlin = 'param uniqueness_params=ilk default.option.example.com -w test'
    assert_output("\n") { puts `bin/noodlin #{noodlin}` }

    # Refresh options
    assert_output("Your options had a nap and they are nicely refreshed.\n") { puts `bin/noodlin optionrefresh`}

    post '/nodes/zippyziggy.example.com', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status
  end
end

# 3/14/2017: Ran all tests 3 times without this and only once did a single test fail:
# sleep(1) # wait a sec for the server to be booted
# So, um, I'll leave it out for a while.
# 4/16/2017: Welp, today tests fail without this sleep :(
# One day I'll track it down!
# 12/13/2019: Still trouble with out this sleep
sleep 1
