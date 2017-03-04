require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow creating a node via POST" do
    post '/nodes/jojo.example.com', '{"params":{"ilk":"host","status":"surplus","site":"moon","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201

    r = MultiJson.load last_response.body
    assert_equal r['name'],             'jojo.example.com'
    assert_equal r['params']['ilk'],    'host'
    assert_equal r['params']['status'], 'surplus'
    assert_equal r['params']['site'],   'moon'
    assert_equal r['facts']['fqdn'],    'jojo.example.com'
  end
end

