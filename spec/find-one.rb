require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by FQDN" do
    post '/nodes/zyyz.example.com?now', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status

    get "/nodes/_/zyyz.example.com"
    assert_equal 200, last_response.status

    r = YAML.load last_response.body
    assert_equal 'host',    r['parameters']['ilk']
    assert_equal 'enabled', r['parameters']['status']
    assert_equal 'jupiter', r['parameters']['site']
  end
end

