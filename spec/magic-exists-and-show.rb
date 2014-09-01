require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding and showing with TERM?=" do
    put '/nodes/lolo.example.com', params = '{"ilk":"host","status":"enabled","params":{"site":"jupiter", "funky":"town"}}'
    assert_equal last_response.status, 201
    Node.gateway.refresh_index!

    get "/nodes/_/funky#{CGI.escape('?=')}"
    assert_equal last_response.status, 200
    assert last_response.body.must_include 'yoyo.example.com funky=town'
  end
end

