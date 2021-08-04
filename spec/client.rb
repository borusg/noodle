
#!/usr/bin/env ruby
# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'
require './lib/noodle/client.rb'
require 'securerandom'
require 'pry'
#trying to get the client module/class working . I dont thing this(^^^) is needed, but put something down to keep moving with ideas.

describe 'Noodle' do
    it 'test the client' do
        NoodleClient.server = 'localhost'
        NoodleClient.port = 9292
        # running on docker for now, so these are the settings for it
        project   = %w{hr financials lms registration warehouse}
        prodlevel = %w{dev preprod prod test}
        status    = %w{disabled enabled future surplus}
        site      = %w{jupiter mars moon neptune pluto uranus}
        ilk       = %w{host esx ucschassis ucsfi}

        #facts = JSON.load(File.read("#{__dir__}/facts.json"))

        fqdn = SecureRandom.uuid.gsub('-','') + '.example.com'
        node = NoodleClient.new(fqdn)
        #node.facts = facts
        node.facts['fqdn']           = fqdn
        node.params['created_by']      = 'test'
        node.params['last_updated_by'] = 'test'
        node.params['project']   = project[rand(project.size)]
        node.params['prodlevel'] = prodlevel[rand(prodlevel.size)]
        node.params['site']      = site[rand(site.size)]
        node.params['ilk']       = 'host'
        node.params['status']    = 'enabled' #status[rand(status.size)]


        # create and entry
        assert_equal 201, node.create.code.to_i
        # find the entry
        sleep 1 # make sure it updated
        assert_equal String, NoodleClient.magic(node.name).presence.class
        # Find one entry (is it an JSON still)
        # NoodleClient.findone('name' => '1b651ec518364fe999dd93bf06ca6191.example.com', 'ilk' => 'host') # not working, but trying
        #update the entry

        # to json?

        # delete node

        # look for node again

        binding.pry()
    end
end
