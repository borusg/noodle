require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by @TERM?" do
    put '/nodes/yoyo.example.com', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status
    put '/nodes/soyo.example.com', HappyHelper::node_jupiter
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/@funky?".gsub('?','%3F')
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include 'soyo.example.com'
  end
end

