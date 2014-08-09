require_relative 'spec_helper'

# TODO: Tests like this should really re-use the create/etc tests
# TODO: jojo should be a variable.
describe "Noodle" do
  it "should delete a node" do
    post '/nodes/soso.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    delete '/nodes/soso.example.com'
    assert_equal last_response.status,200
    assert last_response.body.must_include 'Deleted soso.example.com'
  end
end

