# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'
require 'cgi'

describe 'Noodle' do
  it 'allow finding by listing two FQDNs' do
    post '/nodes/yyz.example.com?now', HappyHelper.node_funky_jupiter
    assert_equal 201, last_response.status
    post '/nodes/zzy.example.com?now', HappyHelper.node_funky_jupiter
    assert_equal 201, last_response.status

    get "/nodes/_/yyz.example.com%20zzy.example.com"
    assert_equal 200, last_response.status

    r = YAML.safe_load last_response.body
    assert_equal 'host',   r['parameters']['ilk']
    assert_equal 'enabled', r['parameters']['status']
    assert_equal 'jupiter', r['parameters']['site']
  end
end
