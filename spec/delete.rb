require_relative 'spec_helper'

describe 'Noodle' do
  it "should delete a node" do
    post '/nodes/soso.example.com', HappyHelper::node_moon
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    delete '/nodes/soso.example.com'
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include 'Deleted soso.example.com'
  end
end

