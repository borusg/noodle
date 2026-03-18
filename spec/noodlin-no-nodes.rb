# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'fail when no nodes specified in noodlin' do
    payload = ['param', 'role=db', '-w', 'test'].to_json
    put '/nodes/noodlin/', payload
    assert_equal 400, last_response.status
    assert _(last_response.body).must_include 'No nodes specified.'
  end
end
