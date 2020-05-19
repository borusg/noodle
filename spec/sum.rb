require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow sum to work" do
    put '/nodes/zyyz.example.com', HappyHelper::node_jupiter(magnitude: 4)
    assert_equal 201, last_response.status
    put '/nodes/zxxz.example.com', HappyHelper::node_jupiter(magnitude: 40)
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/ilk=host%20magnitude+".gsub('+','%2B')
    assert_equal 200, last_response.status

    assert _(last_response.body).must_include 'magnitude=44.0'
  end
end
