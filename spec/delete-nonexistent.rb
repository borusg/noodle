require_relative 'spec_helper'

describe 'Noodle' do
  it "should fail to delete a node that doesn't exist" do
    delete '/nodes/hoho.example.com'
    assert_equal last_response.status,422
    assert _(last_response.body).must_include 'hoho.example.com does not exist'
  end
end

