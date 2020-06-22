# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'NOT allow creating a node via PUT' do
    put '/nodes/popo.example.com', HappyHelper.node_moon
    assert_equal 400, last_response.status
    assert_equal "Did not find exactly one match. Matches found: 0\n", last_response.body
  end
end
