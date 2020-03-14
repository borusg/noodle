require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by @TERM=VALUE and -TERM=VALUE" do
    put '/nodes/xoxo.example.com', HappyHelper::node_saturn
    assert_equal last_response.status, 201
    put '/nodes/nono.example.com', HappyHelper::node_saturn
    assert_equal last_response.status, 201
    put '/nodes/oooo.example.com', HappyHelper::node_venus
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    # "Don't @ me!" :)
    get '/nodes/_/@at_me=yes%20magic_dne=yes'
    assert_equal last_response.status, 200
    assert_equal last_response.body, "oooo.example.com\n"

    get '/nodes/_/-at_me=yes%20magic_dne=yes'
    assert_equal last_response.status, 200
    assert_equal last_response.body, "oooo.example.com\n"
  end
end

