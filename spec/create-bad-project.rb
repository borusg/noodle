require_relative 'spec_helper'

describe 'Noodle' do
  it "should fail to create a node with a bad project name" do
    post '/nodes/pigglywiggly.example.com', HappyHelper::node_piggly
    assert_equal last_response.status, 400
    assert _(last_response.body).must_include 'project is not one of these:'
  end
end

