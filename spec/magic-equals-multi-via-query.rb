require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=VALUE1 TERM2=VALUE2' via query (nodes/_/?blah blah)" do
    put '/nodes/kiki.example.com', HappyHelper::node_pluto
    assert_equal last_response.status, 201
    put '/nodes/cici.example.com', HappyHelper::node_prod_pluto
    assert_equal last_response.status, 201

    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/?site=pluto%20prodlevel=prod'
    assert_equal last_response.status, 200
    assert_equal last_response.body, "cici.example.com\n"
  end
end

