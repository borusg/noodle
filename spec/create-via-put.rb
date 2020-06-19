# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'NOT allow creating a node via PUT' do
    put '/nodes/popo.example.com', HappyHelper.node_moon
    assert_equal last_response.status, 422
  end
end
