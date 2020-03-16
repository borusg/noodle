require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=~VALUE1 TERM2=~VALUE2'" do
    put '/nodes/vovo.example.com', HappyHelper::node_neptune
    assert_equal 201, last_response.status
    put '/nodes/toto.example.com', HappyHelper::node_prod_neptune
    assert_equal 201, last_response.status

    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/site=~nept%20prodlevel=~pro'
    assert_equal 200, last_response.status
    assert_equal "toto.example.com\n", last_response.body
  end
end

