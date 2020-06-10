require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by TERM?" do
    post '/nodes/yoyo.example.com?now', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status

    get "/nodes/_/funky#{CGI.escape('?')}"
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include 'yoyo.example.com'
  end
end

