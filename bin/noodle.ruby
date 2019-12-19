#!/usr/bin/ruby

# 'noodle' script for systems with Curl < 7.18.0 when
# --data-urlencode was added.  Or maybe you just prefer
# Ruby to Curl?
#
# Unlike everything else, this is supposed to work with Ruby
# 1.8.5 and higher so it works on RHEL5

require 'uri'
require 'net/http'
require 'optimist'

ENV['NOODLE_SERVER'] = 'localhost:9292' if ENV['NOODLE_SERVER'].nil?

opts = Optimist::options do
    opt :refresh, 'Refresh Noodle options and bareword terms (AKA voodoo)'
    opt :debug, 'Display debug info'
end

maybe_refresh = opts[:refresh] ? '?refresh' : ''

noodle_query = URI.encode(ARGV.join(' '))
uri = URI("http://#{ENV['NOODLE_SERVER']}/nodes/_/#{noodle_query}#{maybe_refresh}")

puts "URI is #{uri}" if opts[:debug]
puts Net::HTTP.get(uri)

