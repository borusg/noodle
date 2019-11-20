require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it "should allow finding by hostname or FQDN and give Puppet ENC YAML output" do
    put '/nodes/ioio.example.com', '{"params":{"ilk":"host","status":"enabled","site":"jupiter", "funky":"town","project":"hr","prodlevel":"dev"}}'
    assert_equal last_response.status, 201
    Noodle::NodeRepository.repository.refresh_index!

    get "/nodes/_/ioio.example.com"
    assert_equal last_response.status, 200
    assert _(last_response.body).must_include '---
classes:
- baseclass
parameters:
  ilk: host
  status: enabled
  site: jupiter
  funky: town
  project: hr
  prodlevel: dev
'
  end
end

