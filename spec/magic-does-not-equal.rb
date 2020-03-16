require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by @TERM=VALUE and -TERM=VALUE" do
    put '/nodes/xoxo.example.com', HappyHelper::node_saturn
    assert_equal 201, last_response.status
    put '/nodes/nono.example.com', HappyHelper::node_saturn
    assert_equal 201, last_response.status
    put '/nodes/oooo.example.com', HappyHelper::node_venus
    assert_equal 201, last_response.status
    Noodle::NodeRepository.repository.refresh_index!

    # "Don't @ me!" :)
    get '/nodes/_/@at_me=yes%20magic_dne=yes'
    assert_equal 200, last_response.status
    assert_equal "oooo.example.com\n", last_response.body

    get '/nodes/_/-at_me=yes%20magic_dne=yes'
    assert_equal 200, last_response.status
    assert_equal "oooo.example.com\n", last_response.body
  end
end

