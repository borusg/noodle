# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it 'allow finding by hostname or FQDN and give Puppet ENC YAML output' do
    post '/nodes/ioio.example.com?now', HappyHelper.node_funky_jupiter
    assert_equal 201, last_response.status

    get '/nodes/_/ioio.example.com'
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include '---
parameters:
  created_by: spec
  funky: town
  ilk: host
  last_updated_by: spec
  prodlevel: dev
  project: hr
  role:
  - fly
  - pigs
  site: jupiter
  status: enabled
classes:
- baseclass
'
  end
end
