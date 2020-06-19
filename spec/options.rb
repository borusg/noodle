# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'respond to OPTIONS for /nodes/blah' do
    options '/nodes/qoqo.example.com'
    assert_equal 200, last_response.status
    assert _(last_response.headers['Allow']).must_include 'DELETE, GET, OPTIONS, PATCH, POST, PUT'
  end
end
