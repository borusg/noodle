# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'fail to patch a node that doesn\'t exist' do
    patch '/nodes/hoho.example.com', '{"site":"mars"}}'
    assert_equal 423, last_response.status
    assert _(last_response.body).must_include 'hoho.example.com does not exist'
  end
end
