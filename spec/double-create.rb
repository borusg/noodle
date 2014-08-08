require_relative 'spec_helper'

describe "Noodle" do
  it "should fail to create a node with the same name as an existing node" do
    post '/nodes/jojo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    post '/nodes/jojo.example.com', params = '{"ilk":"yabba","status":"foo","params":{"site":"moon"}}'
    assert_equal last_response.status,422
    assert last_response.body.must_include 'jojo.example.com already exists'
  end
end

