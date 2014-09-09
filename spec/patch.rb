require_relative 'spec_helper'

describe 'Noodle' do
  it "should patch a node" do
    put '/nodes/dodo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    assert_equal last_response.status,201
    Noodle::Node.gateway.refresh_index!

    patch '/nodes/dodo.example.com', params = '{"params":{"site":"mars"}}'
    assert_equal last_response.status,200
    Noodle::Node.gateway.refresh_index!

    r = MultiJson.load last_response.body
    assert_equal r['name'],           'dodo.example.com'
    assert_equal r['ilk'],            'host'
    assert_equal r['status'],         'surplus'
    assert_equal r['params']['site'], 'mars'
    assert_equal r['facts']['fqdn'],  'dodo.example.com'
  end
end

