require_relative 'spec_helper'

describe 'Noodle' do
  it "should patch a node" do
    post '/nodes/dodo.example.com?now', params = HappyHelper::node_moon
    assert_equal 201, last_response.status

    patch '/nodes/dodo.example.com?now', params = '{"params":{"site":"mars"}}'
    assert_equal 200, last_response.status

    r = MultiJson.load last_response.body
    assert_equal 'dodo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'mars',             r['params']['site']
    assert_equal 'dodo.example.com', r['facts']['fqdn']
  end
end

