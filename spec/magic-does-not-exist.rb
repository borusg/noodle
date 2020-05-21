require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by @TERM?" do
    put '/nodes/yoyo.example.com', HappyHelper::node_funkymonkey_jupiter
    assert_equal 201, last_response.status
    put '/nodes/soyo.example.com', HappyHelper::node_jupiter
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/@funkymonkey"
    assert_equal 200, last_response.status
    assert_equal "yoyo.example.com\n", last_response.body
  end
end

