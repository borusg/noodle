# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow TERM= to show a fact value' do
    post '/nodes/factshow.example.com?now', HappyHelper.node_jupiter
    assert_equal 201, last_response.status

    get '/nodes/_/factshow.example.com%20fqdn='
    assert_equal 200, last_response.status
    assert_equal "factshow.example.com fqdn=factshow.example.com\n", last_response.body
  end
end
