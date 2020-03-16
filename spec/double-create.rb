require_relative 'spec_helper'

describe 'Noodle' do
  it "should fail to create a node with the same name as an existing node" do
    post '/nodes/zozo.example.com?now', HappyHelper::node_jupiter
    assert_equal 201, last_response.status, 'First create'
    Noodle::NodeRepository.repository.refresh_index!

    post '/nodes/zozo.example.com', HappyHelper::node_prod_jupiter
    assert_equal 422, last_response.status, 'Second create'
    assert _(last_response.body).must_include 'zozo.example.com already exists'
  end
end

