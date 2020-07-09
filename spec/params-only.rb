# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'json_params_only' do
    hostname = 'paramsonly.example.com'
    post "/nodes/#{hostname}?now", HappyHelper.node_jupiter
    assert_equal 201, last_response.status

    get "/nodes/_/#{hostname}%20json_params_only"
    r = MultiJson.load(last_response.body).first
    assert_equal hostname, r['name']
    assert_equal 'host', r['params']['ilk']
    assert_equal 'jupiter', r['params']['site']
    assert_equal true, r['facts']['magnitude'].nil?
  end
end
