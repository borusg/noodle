require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by 'TERM1=VALUE1 TERM2=VALUE2'" do
    put '/nodes/koko.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201
    put '/nodes/coco.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter","prodlevel":"prod","project":"hr"}}'
    assert_equal last_response.status, 201

    Noodle::Node.gateway.refresh_index!

    get '/nodes/_/site=jupiter%20prodlevel=prod'
    assert_equal last_response.status, 200
    assert_equal last_response.body, "coco.example.com\n"
  end
end

