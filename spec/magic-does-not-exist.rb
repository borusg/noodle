require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by @TERM?" do
    post '/nodes/yoyo.example.com?now', HappyHelper::node_funkymonkey_jupiter_dnex
    assert_equal 201, last_response.status
    post '/nodes/soyo.example.com?now', HappyHelper::node_funky_jupiter_dnex
    assert_equal 201, last_response.status

    get "/nodes/_/@funkymonkey dnex=yep".gsub(' ', '%20')
    assert_equal 200, last_response.status
    assert_equal "soyo.example.com\n", last_response.body
  end
end

