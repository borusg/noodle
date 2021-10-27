# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'patch a node' do
    # Create node
    post '/nodes/dodo.example.com?now', HappyHelper.node_moon
    assert_equal 201, last_response.status

    # Verify the node was created correctly
    params = { params: { ilk: 'host' } }.to_json
    get '/nodes/dodo.example.com', params
    assert_equal 200, last_response.status
    r = MultiJson.load(last_response.body)
    assert_equal 'dodo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'moon',             r['params']['site']
    assert_equal 'purple',           r['params']['color']
    assert_equal 'jack',             r['facts']['thatsa']
    create_time = r['facts']['noodle_create_time']

    # Patch, change site to mars
    params = { params: { ilk: 'host', site: 'mars' } }.to_json
    patch '/nodes/dodo.example.com?now', params
    assert_equal 200, last_response.status

    # Verify PATCH returned the node we expected
    r = MultiJson.load last_response.body
    assert_equal 'dodo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'mars',             r['params']['site']

    # TODO: Temporary workaround until elasticsearch-persistence
    # supports query param options in update
    sleep 5

    # Now verify that the node was correctly saved to the backend
    params = { params: { ilk: 'host' } }.to_json
    get '/nodes/dodo.example.com', params
    assert_equal 200, last_response.status

    r = MultiJson.load(last_response.body)
    assert_equal 'dodo.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'mars',             r['params']['site']
    assert_equal 'purple',           r['params']['color']
    assert_equal 'jack',             r['facts']['thatsa']
    assert_equal create_time,        r['facts']['noodle_create_time']
  end
end
