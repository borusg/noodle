require_relative 'spec_helper'
require 'uri'

describe "Noodle" do
  it "should allow finding by @TERM=VALUE and -TERM=VALUE" do
    put '/nodes/xoxo.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"jupiter", "justfora":"test"}}'
    assert_equal last_response.status, 201
    put '/nodes/nono.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"jupiter", "justfora":"test"}}'
    assert_equal last_response.status, 201
    put '/nodes/oooo.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"uranus", "justfora":"test"}}'
    assert_equal last_response.status, 201
    Node.gateway.refresh_index!

    get "/nodes/_/@site=jupiter#{URI.escape(' ')}justfora=test"
    assert_equal last_response.status, 200
    assert_equal last_response.body, "oooo.example.com\n"

    get "/nodes/_/-site=jupiter#{URI.escape(' ')}justfora=test"
    assert_equal last_response.status, 200
    assert_equal last_response.body, "oooo.example.com\n"
  end
end

