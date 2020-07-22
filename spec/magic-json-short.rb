# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'limits JSON output to requested facts/params' do
    post '/nodes/discus.example.com?now', HappyHelper.node_jupiter_json
    assert_equal 201, last_response.status

    get '/nodes/_/output=json%20prodlevel=%20json'
    assert_equal 200, last_response.status
    puts last_response.body
    r = MultiJson.load(last_response.body).first
    # We expect a single param:
    assert_equal r['params'].keys, ['prodlevel']
    # and no facts:
    assert_equal r['facts'].keys, []
  end
end
