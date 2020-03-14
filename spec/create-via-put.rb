require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow creating a node via PUT" do
    put '/nodes/popo.example.com', HappyHelper.node_moon
    assert_equal last_response.status, 201

    r = MultiJson.load last_response.body
    assert_equal r['name'],             'popo.example.com'
    assert_equal r['params']['ilk'],    'host'
    assert_equal r['params']['status'], 'surplus'
    assert_equal r['params']['site'],   'moon'
    assert_equal r['facts']['fqdn'],    'popo.example.com'
  end
end

