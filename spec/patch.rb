# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'patch a node' do
    post '/nodes/dodo.example.com?now', HappyHelper.node_moon
    assert_equal 201, last_response.status

    params = { params: { ilk: 'host', site: 'mars' } }.to_json
    patch '/nodes/dodo.example.com?now', params
    assert_equal 200, last_response.status

    r = MultiJson.load last_response.body
    assert_equal 'dodo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'mars',             r['params']['site']
  end
end
