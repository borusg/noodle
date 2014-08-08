require_relative 'spec_helper'

describe "Noodle" do
  it "should allow creating a node" do
    post '/nodes/jojo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    assert_equal last_response.status, 201
    assert_equal last_response.body, 'fixme'
  end
end

