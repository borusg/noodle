# Rubocop says:
# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Noodle' do
  it 'error if GET without ilk' do
    get '/nodes/sample.example.com'
    assert_equal 400, last_response.status
    assert_equal "No ilk supplied so cannot check uniqueness.\n", last_response.body
  end
end
