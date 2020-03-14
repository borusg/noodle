require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=VALUE1 TERM2=VALUE2'" do
    put '/nodes/koko.example.com', HappyHelper::node_jupiter
    assert_equal last_response.status, 201
    put '/nodes/coco.example.com', HappyHelper::node_prod_jupiter
    assert_equal last_response.status, 201

    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/site=jupiter%20prodlevel=prod'
    assert_equal last_response.status, 200
    assert_equal last_response.body, "coco.example.com\n"
  end
end

