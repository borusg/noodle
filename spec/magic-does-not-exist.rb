require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by @TERM?" do
    put '/nodes/yoyo.example.com', HappyHelper::node_funky_jupiter
    assert_equal last_response.status, 201
    put '/nodes/soyo.example.com', HappyHelper::node_jupiter
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/@funky?".gsub('?','%3F')
    assert_equal last_response.status, 200
    assert _(last_response.body).must_include 'soyo.example.com'
  end
end

