require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by TERM?" do
    put '/nodes/yoyo.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter", "funky":"town","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201
    Noodle::Node.gateway.refresh_index!

    get "/nodes/_/funky#{CGI.escape('?')}"
    assert_equal last_response.status, 200
    assert last_response.body.must_include 'yoyo.example.com'
  end
end

