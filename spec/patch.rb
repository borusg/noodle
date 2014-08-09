require_relative 'spec_helper'

describe "Noodle" do
  it "should patch a node" do
    put '/nodes/dodo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    patch '/nodes/dodo.example.com', params = '{"params":{"site":"mars"}}'
    assert_equal last_response.status,200
    assert_equal last_response.body, <<EOF
Name:   dodo.example.com
Ilk:    host
Status: surplus
Params:
  site = mars
Facts:
EOF
  end
end

