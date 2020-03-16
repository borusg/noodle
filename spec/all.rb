require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow GET all nodes via /nodes" do
    delete '/nodes'
    assert_equal 200, last_response.status

    post '/nodes/gigi.example.com', HappyHelper::node_mars
    assert_equal 201, last_response.status
    post '/nodes/hihi.example.com', HappyHelper::node_mars
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes'
    assert_equal 200, last_response.status
    assert_equal 'gigi.example.com
hihi.example.com', last_response.body
  end
end

