require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by hostname or FQDN and give Puppet ENC YAML output" do
    post '/nodes/ioio.example.com?now', HappyHelper::node_funky_jupiter
    assert_equal 201, last_response.status

    get "/nodes/_/ioio.example.com"
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include '---
classes:
- baseclass
parameters:
  site: jupiter
  last_updated_by: spec
  ilk: host
  funky: town
  project: hr
  created_by: spec
  prodlevel: dev
  status: enabled
'
  end
end

