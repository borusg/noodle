# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow creating a node via POST' do
    post '/nodes/jojo.example.com?now', HappyHelper.node_moon
    assert_equal 201, last_response.status

    r = MultiJson.load last_response.body
    assert_equal 'jojo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'moon',             r['params']['site']
    assert_equal 'jojo.example.com', r['facts']['fqdn']
  end
end
