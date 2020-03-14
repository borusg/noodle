require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow sum to work" do
    put '/nodes/zyyz.example.com', HappyHelper::node_jupiter(magnitude: 4)
    assert_equal last_response.status, 201
    put '/nodes/zxxz.example.com', HappyHelper::node_jupiter(magnitude: 40)
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/ilk=host%20magnitude+".gsub('+','%2B')
    assert_equal last_response.status, 200

    assert _(last_response.body).must_include 'magnitude=44.0'
  end
end

