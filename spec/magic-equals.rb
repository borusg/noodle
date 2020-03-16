require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by TERM=VALUE" do
    put '/nodes/roro.example.com', HappyHelper::node_jupiter
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/site=jupiter'
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include 'roro.example.com'
  end
end

