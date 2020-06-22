# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'fail to patch a node that doesn\'t exist' do
    params = { params: { ilk: 'host', site: 'mars' } }.to_json
    patch '/nodes/hoho.example.com', params
    assert_equal 400, last_response.status
    assert _(last_response.body).must_include "Did not find exactly one match. Matches found: 0\n"
  end
end
