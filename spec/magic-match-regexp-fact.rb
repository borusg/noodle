# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow finding by FACT=~REGEXP' do
    post '/nodes/regexpfact.example.com?now', HappyHelper.node_moon
    assert_equal 201, last_response.status

    get '/nodes/_/fqdn=~regexpfact'
    assert_equal 200, last_response.status
    assert _(last_response.body).must_include 'regexpfact.example.com'
  end
end
