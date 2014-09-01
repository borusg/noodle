require_relative 'spec_helper'

describe 'Noodle' do
  it "should fail to patch a node that doesn't exist" do
    patch '/nodes/hoho.example.com', params = '{"params":{"site":"mars"}}'
    assert_equal last_response.status,422
    assert last_response.body.must_include 'hoho.example.com does not exist'
  end
end

