require_relative 'spec_helper'

describe "Noodle" do
  it "should delete a node" do
    post '/nodes/soso.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    # If you don't wait, sometimes it doesn't exist in ES yet.  Race ya!
    sleep 1
    delete '/nodes/soso.example.com'
    assert_equal last_response.status,200
    assert last_response.body.must_include 'Deleted soso.example.com'
  end
end

