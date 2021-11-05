require 'rubygems'
require 'bundler'

Bundler.require

require './lib/noodle'

ElasticAPM.start(app: Noodle)
run Noodle
at_exit { ElasticAPM.stop }
