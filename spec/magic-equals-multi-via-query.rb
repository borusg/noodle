require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=VALUE1 TERM2=VALUE2' via query (nodes/_/?blah blah)" do
    post '/nodes/kiki.example.com?now', HappyHelper::node_pluto
    assert_equal 201, last_response.status
    post '/nodes/cici.example.com?now', HappyHelper::node_prod_pluto
    assert_equal 201, last_response.status

    get '/nodes/_/?site=pluto%20prodlevel=prod'
    assert_equal 200, last_response.status
    assert_equal "cici.example.com\n", last_response.body
  end
end

