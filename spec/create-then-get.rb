# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow GETting a node after creating node via POST' do
    post '/nodes/gogo.example.com?now', HappyHelper.node_moon
    assert_equal 201, last_response.status

    r = MultiJson.load last_response.body
    assert_equal 'gogo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'moon',             r['params']['site']
    assert_equal 'gogo.example.com', r['facts']['fqdn']

    get '/nodes/gogo.example.com'
    assert_equal 200, last_response.status

    # TODO: DRY
    # TODO: Should fix body so ternary isn't needed here:
    r = last_response.body.empty? ? {} : MultiJson.load(last_response.body)
    assert_equal 'gogo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'moon',             r['params']['site']
    assert_equal 'gogo.example.com', r['facts']['fqdn']
  end
end
