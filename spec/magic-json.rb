require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow output in JSON format" do
    put '/nodes/fofo.example.com?now', HappyHelper::node_jupiter_json
    assert_equal 201, last_response.status

    get '/nodes/_/output=json%20json'
    assert_equal 200, last_response.status
    r = MultiJson.load(last_response.body).first
    assert_equal 'fofo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'enabled',          r['params']['status']
    assert_equal 'jupiter',          r['params']['site']
    assert_equal 'json',             r['params']['output']
    assert_equal 'fofo.example.com', r['facts']['fqdn']
  end
end

