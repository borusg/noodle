require_relative 'spec_helper'

describe "Noodle" do
  it "should allow creating a node via PUT" do
    put '/nodes/popo.example.com', params = '{"ilk":"host","status":"surplus","params":{"site":"moon"}}'
    assert_equal last_response.status, 201
    assert_equal last_response.body, <<EOF
Name:   popo.example.com
Ilk:    host
Status: surplus
Params:
  site = moon
Facts:
EOF
  end
end

