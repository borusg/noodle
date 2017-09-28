#!/usr/bin/ruby

require 'securerandom'
require './lib/noodle/client.rb'

#bin/noodlin create -i host -s neptune -p hr -P dev -f cpus=2 -f ramgigs=16 -f diskgigs=8 -a role=web,mariadb marille.example.com

project   = %w{hr financials lms registration warehouse}
prodlevel = %w{dev preprod prod test}
status    = %w{disabled enabled future surplus}
site      = %w{jupiter mars moon neptune pluto uranus}
ilk       = %w{host esx ucschassis ucsfi}

facts = JSON.load(File.read('facts.json'))

1000.times do
    fqdn = SecureRandom.uuid.gsub('-','') + '.example.com'
    node = Noodle::Client.new(fqdn)
    node.facts = facts
    node.facts['fqdn']           = fqdn
    node.facts['processorcount'] = rand(16) + 1
    node.facts['ram_gigs']       = rand(64) + 1
    node.facts['storage_gigs']   = rand(1024) + 1
    node.params['project']   = project[rand(project.size)]
    node.params['prodlevel'] = prodlevel[rand(prodlevel.size)]
    node.params['site']      = site[rand(site.size)]
    node.params['ilk']       = 'host'
    node.params['status']    = 'enabled' #status[rand(status.size)]

    s = node.create
    unless s.code == '201'
        puts "Gack, bad status creating #{fqdn}: #{s}"
        exit 1
    end
end
