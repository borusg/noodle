require_relative 'spec_helper'

describe 'Noodle' do
  it "should fail to create a node with the same name as an existing node" do
    post '/nodes/zozo.example.com', '{"params":{"ilk":"host","status":"surplus","site":"moon","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201, 'First create'
    Noodle::Node.gateway.refresh_index!

    post '/nodes/zozo.example.com', '{"params":{"ilk":"yabba","status":"foo","site":"moon","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 422, 'Second create'
    assert last_response.body.must_include 'zozo.example.com already exists'
  end
end

