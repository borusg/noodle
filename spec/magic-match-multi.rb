require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=~VALUE1 TERM2=~VALUE2'" do
    put '/nodes/vovo.example.com', HappyHelper::node_neptune
    assert_equal last_response.status, 201
    put '/nodes/toto.example.com', HappyHelper::node_prod_neptune
    assert_equal last_response.status, 201

    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/site=~nept%20prodlevel=~pro'
    assert_equal last_response.status, 200
    assert_equal last_response.body, "toto.example.com\n"
  end
end

