require_relative 'spec_helper'

describe 'Noodle' do
  it "should patch a node" do
    put '/nodes/dodo.example.com', params = '{"params":{"ilk":"host","status":"surplus","site":"moon","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status,201
    Noodle::NodeRepository.repository.refresh_index!

    patch '/nodes/dodo.example.com', params = '{"params":{"site":"mars"}}'
    assert_equal last_response.status,200
    Noodle::NodeRepository.repository.refresh_index!

    r = MultiJson.load last_response.body
    assert_equal r['name'],             'dodo.example.com'
    assert_equal r['params']['ilk'],    'host'
    assert_equal r['params']['status'], 'surplus'
    assert_equal r['params']['site'],   'mars'
    assert_equal r['facts']['fqdn'],    'dodo.example.com'
  end
end

