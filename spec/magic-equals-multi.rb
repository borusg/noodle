require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=VALUE1 TERM2=VALUE2'" do
    put '/nodes/koko.example.com', HappyHelper::node_jupiter
    assert_equal 201, last_response.status
    put '/nodes/coco.example.com', HappyHelper::node_prod_jupiter
    assert_equal 201, last_response.status

    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/site=jupiter%20prodlevel=prod'
    assert_equal 200, last_response.status
    assert_equal "coco.example.com\n", last_response.body
  end
end

