require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow GET all nodes via /nodes" do
    delete '/nodes'
    assert_equal last_response.status, 200

    post '/nodes/gigi.example.com', HappyHelper::node_mars
    assert_equal last_response.status, 201
    post '/nodes/hihi.example.com', HappyHelper::node_mars
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes'
    assert_equal last_response.status, 200
    assert_equal last_response.body, 'gigi.example.com
hihi.example.com'
  end
end

