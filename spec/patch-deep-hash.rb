# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'patch a node' do
    # Create node
    post '/nodes/hashmash.example.com?now', HappyHelper.node_hashy
    assert_equal 201, last_response.status

    # Verify the node was created correctly
    params = { params: { ilk: 'host' } }.to_json
    get '/nodes/hashmash.example.com', params
    assert_equal 200, last_response.status
    r = MultiJson.load(last_response.body)
    assert_equal 'hashmash.example.com', r['name']
    assert_equal 'host',             r['params']['ilk']
    assert_equal 'surplus',          r['params']['status']
    assert_equal 'moon',             r['params']['site']
    assert_equal 'purple',           r['params']['color']

    # Patch, change facts.this.is.a.nested.hash.value
    params = { params: { ilk: 'host' }, facts: { this: { is: { a: { nested: { hash: { value: 8 } } } } } } }.to_json
    patch '/nodes/hashmash.example.com?now', params
    assert_equal 200, last_response.status

    # TODO: Temporary workaround until elasticsearch-persistence
    # supports query param options in update
    sleep 5

    ##
    # Now verify that the node was correctly saved to the backend
    #
    params = { params: { ilk: 'host' } }.to_json
    get '/nodes/hashmash.example.com', params
    assert_equal 200, last_response.status
    r = MultiJson.load(last_response.body)
    #
    # First, make sure value is now 8
    assert_equal 8, r['facts']['this']['is']['a']['nested']['hash']['value']
    # Next, make sure it still has as=nested
    assert_equal 'nested', r['facts']['this']['isnt']['as']
    # and very berry
    assert_equal 'berry', r['facts']['this']['is']['a']['very']
  end
end
