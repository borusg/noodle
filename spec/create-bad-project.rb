require_relative 'spec_helper'

describe 'Noodle' do
  it "should fail to create a node with the same name as an existing node" do
    post '/nodes/pigglywiggly.example.com', '{"params":{"ilk":"host","status":"surplus","site":"moon","project":"pigglywiggly","prodlevel":"dev"}}'
    assert_equal last_response.status, 400
    assert _(last_response.body).must_include 'project is not one of these:'
  end
end

