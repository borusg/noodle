require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding and showing with TERM?=" do
    put '/nodes/lolo.example.com', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/funky#{CGI.escape('?=')}"
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include 'lolo.example.com funky=town'
  end
end

