# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'Make sure TERM=VALUE does not match VALUES which are super-strings of VALUE' do
    post '/nodes/lion.example.com?now', HappyHelper.node_neptune
    assert_equal 201, last_response.status
    post '/nodes/stallion.example.com?now', HappyHelper.node_neptune
    assert_equal 201, last_response.status

    get '/nodes/_/fqdn=lion.example.com'
    assert_equal 200, last_response.status
    assert_equal "lion.example.com\n", last_response.body
  end
end
