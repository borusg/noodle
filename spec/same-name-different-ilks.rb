# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'allow creating two nodes with the same name but different ilks' do
    name = 'semicolon.example.com'

    post "/nodes/#{name}?now", HappyHelper.node_moon
    assert_equal 201, last_response.status

    post "/nodes/#{name}", HappyHelper.node_moon_sslcert
    assert_equal 201, last_response.status
  end
end
