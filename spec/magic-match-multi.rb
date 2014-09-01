require_relative 'spec_helper'
require 'uri'

describe 'Noodle' do
  it "should allow finding by 'TERM1=~VALUE1 TERM2=~VALUE2'" do
    put '/nodes/vovo.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"neptune"}}'
    assert_equal last_response.status, 201
    put '/nodes/toto.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"neptune","prodlevel":"prod"}}'
    assert_equal last_response.status, 201

    Node.gateway.refresh_index!

    get "/nodes/_/site=~nept#{URI.escape(' ')}prodlevel=~pro"
    assert_equal last_response.status, 200
    assert_equal last_response.body, "toto.example.com\n"
  end
end

