# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  ten_dot_ten = '10.10.10.0'
  ten_dot_eleven = '10.11.0.0'
  it 'Make sure fqdn=10.10.10.0 does not also return 10.11.0.0' do
    post "/nodes/#{ten_dot_ten}?now", HappyHelper.node_pluto
    assert_equal 201, last_response.status
    post "/nodes/#{ten_dot_eleven}?now", HappyHelper.node_pluto
    assert_equal 201, last_response.status

    get "/nodes/_/fqdn=#{ten_dot_ten}"
    assert_equal 200, last_response.status
    assert_equal "#{ten_dot_ten}\n", last_response.body
  end
end
