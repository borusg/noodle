#!/usr/bin/env ruby

# Creates sample Noodle entries.
#
# PASTA.example.com with random project, prodlevel, site and roles

require './lib/noodle.rb'

options    = Noodle::Option.get.limits
projects   = options['project']
prodlevels = options['prodlevel']
sites      = options['site']

roles1  = %w(db app web)
roles2 = %w(ssh git mariadb elasticsearch puppetmaster)

ilk    = 'host'
status = 'enabled'

File.readlines('util/noodlenames.txt').each do |noodle|
    fqdn     = noodle.strip + '.example.com'
    cpus     = rand(10) + 1
    ramgigs  = 2 ** (rand(8) + 1)
    diskgigs = 2 ** (rand(16) + 1)
    roles    = "#{roles1.sample},#{roles2.sample}"
    print "bin/noodlin create -i #{ilk} -s #{sites.sample} -p #{projects.sample} -P #{prodlevels.sample} -f cpus=#{cpus} -f ramgigs=#{ramgigs} -f diskgigs=#{diskgigs} -a role=#{roles} #{fqdn}\n"
end

