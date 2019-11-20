require_relative 'spec_helper'

describe 'Noodle' do
  it "should allow finding by TERM=VALUE" do
    put '/nodes/roro.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get '/nodes/_/site=jupiter'
    assert_equal last_response.status, 200
    assert _(last_response.body).must_include 'roro.example.com'
  end
end

