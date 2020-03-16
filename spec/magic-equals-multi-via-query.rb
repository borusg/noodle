require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=VALUE1 TERM2=VALUE2' via query (nodes/_/?blah blah)" do
    put '/nodes/kiki.example.com', HappyHelper::node_pluto
    assert_equal 201, last_response.status
    put '/nodes/cici.example.com', HappyHelper::node_prod_pluto
    assert_equal 201, last_response.status

    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/?site=pluto%20prodlevel=prod'
    assert_equal 200, last_response.status
    assert_equal "cici.example.com\n", last_response.body
  end
end

