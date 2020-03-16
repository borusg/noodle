require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow DELETE everything via /nodes" do
    post '/nodes/sisi.example.com', HappyHelper::node_moon
    assert_equal 201, last_response.status
    post '/nodes/titi.example.com', HappyHelper::node_mars
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    delete '/nodes'
    assert_equal 200, last_response.status

    get '/nodes'
    assert_equal 200, last_response.status
    assert_equal '', last_response.body
  end
end

