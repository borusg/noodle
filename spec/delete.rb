require_relative 'spec_helper'

# TODO: Tests like this should really re-use the create/etc tests
# TODO: jojo should be a variable.
describe "Noodle" do
  it "should fail to delete a node that doesn't exist" do
    post '/nodes/jojo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    delete '/nodes/jojo.example.com'
    assert_equal last_response.status,200
    assert last_response.body.must_include 'Deleted jojo.example.com'
  end
end

