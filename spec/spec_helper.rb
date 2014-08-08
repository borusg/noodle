# Stolen from: http://recipes.sinatrarb.com/p/testing/rspec

# spec/spec_helper.rb
require 'rack/test'

require File.expand_path '../../noodle.rb', __FILE__

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Noodle end
end

# For RSpec 2.x
RSpec.configure { |c| c.include RSpecMixin }

