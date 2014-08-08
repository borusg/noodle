require_relative 'spec_helper'

describe "Noodle" do
  it "should allow creating a node" do
    post '/nodes/jojo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    assert last_response.status == 201
    # TODO: This doesn't do anything!
    assert last_response.body = 'fixme'
  end
end

