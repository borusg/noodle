# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'return error when noodlin param targets a node that does not exist' do
    payload = ['param', 'role=db', 'does-not-exist.example.com', '-w', 'test'].to_json
    put '/nodes/noodlin/', payload
    assert_equal 400, last_response.status
    assert_equal 'No nodes matched, no action taken.', last_response.body
  end
end
