require_relative 'spec_helper'

describe 'Noodle' do
  it "should delete a node" do
    post '/nodes/soso.example.com', params = '{"params":{"ilk":"host","status":"surplus","site":"moon","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status,201
    Noodle::Node.gateway.refresh_index!

    delete '/nodes/soso.example.com'
    assert_equal last_response.status,200
    assert last_response.body.must_include 'Deleted soso.example.com'
  end
end

