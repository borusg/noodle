require_relative 'spec_helper'
require 'uri'

describe 'Noodle' do
  it "should allow finding by 'TERM1=VALUE1 TERM2=VALUE2' via query (nodes/_/?blah blah)" do
    put '/nodes/kiki.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"pluto"}}'
    assert_equal last_response.status, 201
    put '/nodes/cici.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"pluto","prodlevel":"prod"}}'
    assert_equal last_response.status, 201

    Noodle::Node.gateway.refresh_index!

    get "/nodes/_/?site=pluto#{URI.escape(' ')}prodlevel=prod"
    assert_equal last_response.status, 200
    assert_equal last_response.body, "cici.example.com\n"
  end
end

