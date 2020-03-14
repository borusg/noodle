require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by hostname or FQDN and give Puppet ENC YAML output" do
    put '/nodes/ioio.example.com', HappyHelper::node_funky_jupiter
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/ioio.example.com"
    assert_equal last_response.status, 200
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

