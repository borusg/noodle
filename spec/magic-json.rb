require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow output in JSON format" do
    put '/nodes/fofo.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"jupiter","output":"json"}}'
    assert_equal last_response.status, 201
    Node.gateway.refresh_index!

    get '/nodes/_/output=json%20json'
    assert_equal last_response.status, 200
    r = MultiJson.load(last_response.body).first
    assert_equal r['name'],             'fofo.example.com'
    assert_equal r['ilk'],              'host'
    assert_equal r['status'],           'enabled'
    assert_equal r['params']['site'],   'jupiter'
    assert_equal r['params']['output'], 'json'
    assert_equal r['facts']['fqdn'],    'fofo.example.com'
  end
end

