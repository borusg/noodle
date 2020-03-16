require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow creating a node via PUT" do
    put '/nodes/popo.example.com', HappyHelper.node_moon
    assert_equal last_response.status, 201

    r = MultiJson.load last_response.body
    assert_equal 'popo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'moon',             r['params']['site']
    assert_equal 'popo.example.com', r['facts']['fqdn']
  end
end

